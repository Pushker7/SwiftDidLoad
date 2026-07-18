import Foundation
import MultipeerConnectivity

@MainActor
final class SocketService: NSObject {
    private let serviceType = "blinkit-cart"
    
    private var myPeerID: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private var localUser: User?
    private var targetCode: String = ""
    
    var onState: (@Sendable @MainActor (SharedCart, [User]) -> Void)?
    var onEvent: (@Sendable @MainActor (String, String, String, String?, Int?) -> Void)?
    var onPeerConnected: (@Sendable @MainActor (User) -> Void)?
    
    func startAdvertising(user: User) {
        self.localUser = user
        let peerID = MCPeerID(displayName: user.name)
        self.myPeerID = peerID
        
        let discoveryInfo = [
            "connectCode": user.code,
            "userId": user.id,
            "colorHex": user.colorHex
        ]
        
        let newSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session = newSession
        newSession.delegate = self
        
        let newAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        self.advertiser = newAdvertiser
        newAdvertiser.delegate = self
        newAdvertiser.startAdvertisingPeer()
    }
    
    func startBrowsing(targetCode: String) {
        guard let myPeerID else { return }
        self.targetCode = targetCode.uppercased()
        
        let newBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        self.browser = newBrowser
        newBrowser.delegate = self
        newBrowser.startBrowsingForPeers()
    }
    
    func stopDiscovery() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
    }
    
    func disconnect() {
        stopDiscovery()
        session?.disconnect()
        session = nil
        myPeerID = nil
        localUser = nil
    }
    
    private func send(_ payload: [String: Any]) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Failed to send P2P data: \(error)")
        }
    }
    
    // Core cart synchronization methods
    func sendCartState(cart: SharedCart, members: [User]) {
        guard let cartData = try? JSONEncoder().encode(cart),
              let cartJson = try? JSONSerialization.jsonObject(with: cartData) as? [String: Any],
              let membersData = try? JSONEncoder().encode(members),
              let membersJson = try? JSONSerialization.jsonObject(with: membersData) as? [[String: Any]] else {
            return
        }
        
        send([
            "type": "cart:state",
            "cart": cartJson,
            "members": membersJson
        ])
    }
    
    func sendEvent(actorId: String, actorName: String, eventType: String, productName: String?, qty: Int?) {
        var payload: [String: Any] = [
            "type": "cart:event",
            "actorId": actorId,
            "actorName": actorName,
            "eventType": eventType
        ]
        if let productName { payload["productName"] = productName }
        if let qty { payload["qty"] = qty }
        send(payload)
    }
    
    // Dummy socket methods to prevent compile errors in existing code
    func connect(cartId: String, userId: String) {
        // Handled by P2P setup
    }
    
    func add(productId: String) {
        // Handled directly via AppState modifying local cart & broadcasting
    }
    
    func updateQty(productId: String, qty: Int) {
        // Handled directly via AppState modifying local cart & broadcasting
    }
    
    func remove(productId: String) {
        // Handled directly via AppState modifying local cart & broadcasting
    }
    
    func checkout() {
        // Handled directly via AppState modifying local cart & broadcasting
    }
}

extension SocketService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                // Exchange profiles
                if let localUser = self.localUser {
                    let profile: [String: Any] = [
                        "type": "sync:profile",
                        "id": localUser.id,
                        "name": localUser.name,
                        "code": localUser.code,
                        "colorHex": localUser.colorHex
                    ]
                    self.send(profile)
                }
            case .connecting:
                break
            case .notConnected:
                break
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else { return }
            
            switch type {
            case "sync:profile":
                if let id = json["id"] as? String,
                   let name = json["name"] as? String,
                   let code = json["code"] as? String,
                   let colorHex = json["colorHex"] as? String {
                    let peerUser = User(id: id, name: name, code: code, colorHex: colorHex, sharedCartId: "shared-cart-p2p")
                    self.onPeerConnected?(peerUser)
                }
            case "cart:state":
                guard
                    let cartData = try? JSONSerialization.data(withJSONObject: json["cart"] ?? [:]),
                    let cart = try? JSONDecoder().decode(SharedCart.self, from: cartData),
                    let membersData = try? JSONSerialization.data(withJSONObject: json["members"] ?? []),
                    let members = try? JSONDecoder().decode([User].self, from: membersData)
                else { return }
                self.onState?(cart, members)
            case "cart:event":
                let actorId = json["actorId"] as? String ?? ""
                let actorName = json["actorName"] as? String ?? ""
                let eventType = json["eventType"] as? String ?? ""
                let productName = json["productName"] as? String
                let qty = json["qty"] as? Int
                self.onEvent?(actorId, actorName, eventType, productName, qty)
            default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {}
}

extension SocketService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            guard let session = self.session else {
                invitationHandler(false, nil)
                return
            }
            invitationHandler(true, session)
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        print("Advertiser failed to start: \(error)")
    }
}

extension SocketService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Task { @MainActor in
            guard let session = self.session, let info = info, let connectCode = info["connectCode"] else { return }
            if connectCode.uppercased() == self.targetCode {
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        print("Browser failed to start: \(error)")
    }
}
