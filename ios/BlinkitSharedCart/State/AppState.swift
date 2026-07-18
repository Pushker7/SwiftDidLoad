import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    var user: User? {
        didSet {
            if let user {
                if let data = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(data, forKey: "localUser")
                }
                UserDefaults.standard.set(user.id, forKey: "userId")
            } else {
                UserDefaults.standard.removeObject(forKey: "localUser")
                UserDefaults.standard.removeObject(forKey: "userId")
            }
        }
    }
    
    var categories: [ProductCategory] = []
    var products: [Product] = []
    var walletBalance: Int = 0

    var personalCart: [PersonalCartItem] = [] {
        didSet { PersonalCartStore.save(personalCart) }
    }

    var sharedCart: SharedCart? {
        didSet {
            if let sharedCart {
                if let data = try? JSONEncoder().encode(sharedCart) {
                    UserDefaults.standard.set(data, forKey: "cachedSharedCart")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "cachedSharedCart")
            }
        }
    }
    
    var members: [User] = [] {
        didSet {
            if !members.isEmpty {
                if let data = try? JSONEncoder().encode(members) {
                    UserDefaults.standard.set(data, forKey: "cachedMembers")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "cachedMembers")
            }
        }
    }

    var toasts: [Toast] = []
    var connectError: String?

    private let socket = SocketService()

    var hasConnections: Bool { user?.sharedCartId != nil }

    func productFor(_ id: String) -> Product? {
        products.first { $0.id == id }
    }

    func memberFor(_ id: String) -> User? {
        members.first { $0.id == id }
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        if let response = try? await APIClient.fetchProducts() {
            categories = response.categories
            products = response.products
        }
        personalCart = PersonalCartStore.load()

        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        do {
            let fetched = try await APIClient.fetchUser(id: userId)
            user = fetched
            
            setupSocketCallbacks()
            socket.startAdvertising(user: fetched)
            
            if let _ = fetched.sharedCartId {
                loadCachedSharedCart()
            }
        } catch {
            UserDefaults.standard.removeObject(forKey: "userId")
            UserDefaults.standard.removeObject(forKey: "localUser")
            user = nil
        }
    }

    func completeOnboarding(name: String) async throws {
        let newUser = try await APIClient.createUser(name: name)
        user = newUser
        
        setupSocketCallbacks()
        socket.startAdvertising(user: newUser)
    }

    func updateName(name: String) {
        guard var updated = user else { return }
        updated.name = name
        user = updated
        socket.startAdvertising(user: updated)
    }

    private func loadCachedSharedCart() {
        if let cartData = UserDefaults.standard.data(forKey: "cachedSharedCart"),
           let cart = try? JSONDecoder().decode(SharedCart.self, from: cartData) {
            sharedCart = cart
        }
        if let membersData = UserDefaults.standard.data(forKey: "cachedMembers"),
           let cachedMembers = try? JSONDecoder().decode([User].self, from: membersData) {
            members = cachedMembers
            // Try to auto-reconnect by searching for the other user's code
            if let other = cachedMembers.first(where: { $0.id != user?.id }) {
                socket.startBrowsing(targetCode: other.code)
            }
        }
    }

    // MARK: - Connections

    func connect(code: String) async {
        connectError = nil
        guard let user else { return }
        // Start P2P discovery by browsing for their code
        socket.startBrowsing(targetCode: code)
        showToast("Searching for code \(code.uppercased())…")
    }

    private func otherMemberName(in members: [User]) -> String? {
        members.first { $0.id != user?.id }?.name
    }

    private func setupSocketCallbacks() {
        socket.onState = { [weak self] cart, members in
            self?.sharedCart = cart
            self?.members = members
        }
        socket.onEvent = { [weak self] actorId, actorName, eventType, productName, qty in
            self?.handleEvent(actorId: actorId, actorName: actorName, eventType: eventType, productName: productName, qty: qty)
        }
        socket.onPeerConnected = { [weak self] peerUser in
            guard let self, let user = self.user else { return }
            
            // Link both users locally
            self.members = [user, peerUser]
            self.user?.sharedCartId = "shared-cart-p2p"
            
            if self.sharedCart == nil {
                self.sharedCart = SharedCart(id: "shared-cart-p2p", name: "Home Cart", memberIds: [user.id, peerUser.id], items: [])
            }
            
            // Send our cart state to the newly connected peer
            self.socket.sendCartState(cart: self.sharedCart!, members: self.members)
            self.socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "join", productName: nil, qty: nil)
            
            self.showToast("Connected with \(peerUser.name)! Home Cart is live 🎉")
            self.socket.stopDiscovery()
        }
    }

    private func handleEvent(actorId: String, actorName: String, eventType: String, productName: String?, qty: Int?) {
        guard actorId != user?.id else { return }
        switch eventType {
        case "add":
            showToast("\(actorName) added \(productName ?? "an item")")
        case "qty":
            showToast("\(actorName) changed \(productName ?? "an item") to \(qty ?? 0)")
        case "remove":
            showToast("\(actorName) removed \(productName ?? "an item")")
        case "checkout":
            showToast("🎉 \(actorName) placed the Home Cart order")
        case "join":
            showToast("\(actorName) joined Home Cart")
        default:
            break
        }
    }

    // MARK: - Personal cart

    func addToPersonalCart(productId: String) {
        if let index = personalCart.firstIndex(where: { $0.productId == productId }) {
            personalCart[index].qty += 1
        } else {
            personalCart.append(PersonalCartItem(productId: productId, qty: 1))
        }
    }

    func setPersonalQty(productId: String, qty: Int) {
        if qty <= 0 {
            personalCart.removeAll { $0.productId == productId }
        } else if let index = personalCart.firstIndex(where: { $0.productId == productId }) {
            personalCart[index].qty = qty
        }
    }

    func clearPersonalCart() {
        personalCart = []
    }

    // MARK: - Shared cart actions

    func addToSharedCart(productId: String) {
        guard let user, var cart = sharedCart else { return }
        let product = productFor(productId)
        if let index = cart.items.firstIndex(where: { $0.productId == productId }) {
            cart.items[index].qty += 1
            sharedCart = cart
            socket.sendCartState(cart: cart, members: members)
            socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "qty", productName: product?.name, qty: cart.items[index].qty)
        } else {
            let newItem = SharedCartItem(productId: productId, qty: 1, addedById: user.id, addedAt: Date().timeIntervalSince1970)
            cart.items.append(newItem)
            sharedCart = cart
            socket.sendCartState(cart: cart, members: members)
            socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "add", productName: product?.name, qty: 1)
        }
    }

    func setSharedQty(productId: String, qty: Int) {
        guard let user, var cart = sharedCart else { return }
        let product = productFor(productId)
        if qty <= 0 {
            cart.items.removeAll { $0.productId == productId }
            sharedCart = cart
            socket.sendCartState(cart: cart, members: members)
            socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "remove", productName: product?.name, qty: nil)
        } else if let index = cart.items.firstIndex(where: { $0.productId == productId }) {
            cart.items[index].qty = qty
            sharedCart = cart
            socket.sendCartState(cart: cart, members: members)
            socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "qty", productName: product?.name, qty: qty)
        }
    }

    func removeFromSharedCart(productId: String) {
        guard let user, var cart = sharedCart else { return }
        let product = productFor(productId)
        cart.items.removeAll { $0.productId == productId }
        sharedCart = cart
        socket.sendCartState(cart: cart, members: members)
        socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "remove", productName: product?.name, qty: nil)
    }

    func moveToMyCart(productId: String, qty: Int) {
        guard let user, var cart = sharedCart else { return }
        let product = productFor(productId)
        cart.items.removeAll { $0.productId == productId }
        sharedCart = cart
        socket.sendCartState(cart: cart, members: members)
        socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "remove", productName: product?.name, qty: nil)
        
        if let index = personalCart.firstIndex(where: { $0.productId == productId }) {
            personalCart[index].qty += qty
        } else {
            personalCart.append(PersonalCartItem(productId: productId, qty: qty))
        }
    }

    func checkoutSharedCart() {
        guard let user, var cart = sharedCart else { return }
        cart.items = []
        sharedCart = cart
        socket.sendCartState(cart: cart, members: members)
        socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "checkout", productName: nil, qty: nil)
    }

    // MARK: - Cart badge

    var cartBadgeCount: Int {
        let personal = personalCart.reduce(0) { $0 + $1.qty }
        let shared = sharedCart?.items.reduce(0) { $0 + $1.qty } ?? 0
        return personal + shared
    }

    // MARK: - Toasts

    func showToast(_ message: String) {
        let toast = Toast(message: message)
        toasts.append(toast)
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            toasts.removeAll { $0.id == toast.id }
        }
    }
}
