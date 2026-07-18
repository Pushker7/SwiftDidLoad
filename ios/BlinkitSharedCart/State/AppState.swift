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

    var carts: [Cart] = [] {
        didSet { PersonalCartStore.save(carts) }
    }
    var activeCartId: String = ""

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

    /// True once a peer is connected — independent of any individual cart being shared.
    var hasConnections: Bool { !members.filter { $0.id != user?.id }.isEmpty }

    var activeCart: Cart? {
        carts.first { $0.id == activeCartId }
    }

    func productFor(_ id: String) -> Product? {
        products.first { $0.id == id }
    }

    func memberFor(_ id: String) -> User? {
        members.first { $0.id == id }
    }

    func cartFor(_ id: String) -> Cart? {
        carts.first { $0.id == id }
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        if let response = try? await APIClient.fetchProducts() {
            categories = response.categories
            products = response.products
        }

        carts = PersonalCartStore.load()
        if carts.isEmpty {
            carts = [Cart(id: "my-cart", name: "My Cart", isShared: false, memberIds: [], items: [])]
        }
        activeCartId = carts.first?.id ?? ""

        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        do {
            let fetched = try await APIClient.fetchUser(id: userId)
            user = fetched
            setupSocketCallbacks()
            socket.startAdvertising(user: fetched)
            loadCachedMembers()
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

    private func loadCachedMembers() {
        guard let membersData = UserDefaults.standard.data(forKey: "cachedMembers"),
              let cachedMembers = try? JSONDecoder().decode([User].self, from: membersData) else { return }
        members = cachedMembers
        // Try to auto-reconnect by browsing for the other member's code.
        if let other = cachedMembers.first(where: { $0.id != user?.id }) {
            socket.startBrowsing(targetCode: other.code)
        }
    }

    // MARK: - Connections

    func connect(code: String) async {
        connectError = nil
        guard user != nil else { return }
        socket.startBrowsing(targetCode: code)
        showToast("Searching for code \(code.uppercased())…")
    }

    private func setupSocketCallbacks() {
        socket.onState = { [weak self] incomingCarts, incomingMembers in
            guard let self else { return }
            self.mergeIncoming(carts: incomingCarts)
            self.members = incomingMembers
        }
        socket.onEvent = { [weak self] actorId, actorName, eventType, productName, qty in
            self?.handleEvent(actorId: actorId, actorName: actorName, eventType: eventType, productName: productName, qty: qty)
        }
        socket.onPeerConnected = { [weak self] peerUser in
            guard let self, let user = self.user else { return }
            self.members = [user, peerUser]
            self.broadcastSharedCarts()
            self.socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "join", productName: nil, qty: nil)
            self.showToast("Connected with \(peerUser.name)! Ready to share carts 🎉")
            self.socket.stopDiscovery()
        }
    }

    /// Full-snapshot merge: upsert every incoming shared cart by id, leave personal carts alone.
    private func mergeIncoming(carts incomingCarts: [Cart]) {
        for incoming in incomingCarts {
            if let index = carts.firstIndex(where: { $0.id == incoming.id }) {
                carts[index] = incoming
            } else {
                carts.append(incoming)
            }
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
            showToast("🎉 \(actorName) placed an order")
        case "join":
            showToast("\(actorName) connected")
        default:
            break
        }
    }

    // MARK: - Cart management

    @discardableResult
    func createCart(name: String, isShared: Bool) -> Cart {
        let newCart = Cart(
            id: UUID().uuidString,
            name: name,
            isShared: isShared,
            memberIds: isShared ? members.map { $0.id } : [],
            items: []
        )
        carts.append(newCart)
        activeCartId = newCart.id
        if isShared { broadcastSharedCarts() }
        return newCart
    }

    func deleteCart(id: String) {
        guard carts.count > 1 else { return }
        carts.removeAll { $0.id == id }
        if activeCartId == id {
            activeCartId = carts.first?.id ?? ""
        }
    }

    /// Toggle a cart between personal and shared. Turning sharing on immediately
    /// broadcasts it so a connected peer sees the new list appear live.
    func setShared(cartId: String, isShared: Bool) {
        guard let index = carts.firstIndex(where: { $0.id == cartId }) else { return }
        carts[index].isShared = isShared
        carts[index].memberIds = isShared ? members.map { $0.id } : []
        if isShared { broadcastSharedCarts() }
    }

    /// Disconnects the peer and demotes every shared cart back to personal (kept locally, no data loss).
    func disconnectPeer() {
        members = []
        for index in carts.indices where carts[index].isShared {
            carts[index].isShared = false
            carts[index].memberIds = []
        }
    }

    private func broadcastSharedCarts() {
        let shared = carts.filter { $0.isShared }
        guard !shared.isEmpty else { return }
        socket.sendCartState(carts: shared, members: members)
    }

    // MARK: - Cart item actions

    func addToCart(cartId: String, productId: String) {
        guard let user, let index = carts.firstIndex(where: { $0.id == cartId }) else { return }
        let product = productFor(productId)
        if let itemIndex = carts[index].items.firstIndex(where: { $0.productId == productId }) {
            carts[index].items[itemIndex].qty += 1
            notifyMutation(cartId: cartId, eventType: "qty", productName: product?.name, qty: carts[index].items[itemIndex].qty, actorId: user.id, actorName: user.name)
        } else {
            let newItem = SharedCartItem(productId: productId, qty: 1, addedById: user.id, addedAt: Date().timeIntervalSince1970)
            carts[index].items.append(newItem)
            notifyMutation(cartId: cartId, eventType: "add", productName: product?.name, qty: 1, actorId: user.id, actorName: user.name)
        }
    }

    func setQty(cartId: String, productId: String, qty: Int) {
        guard let user, let index = carts.firstIndex(where: { $0.id == cartId }) else { return }
        let product = productFor(productId)
        if qty <= 0 {
            carts[index].items.removeAll { $0.productId == productId }
            notifyMutation(cartId: cartId, eventType: "remove", productName: product?.name, qty: nil, actorId: user.id, actorName: user.name)
        } else if let itemIndex = carts[index].items.firstIndex(where: { $0.productId == productId }) {
            carts[index].items[itemIndex].qty = qty
            notifyMutation(cartId: cartId, eventType: "qty", productName: product?.name, qty: qty, actorId: user.id, actorName: user.name)
        }
    }

    func removeFromCart(cartId: String, productId: String) {
        setQty(cartId: cartId, productId: productId, qty: 0)
    }

    func moveItem(productId: String, qty: Int, from sourceCartId: String, to destinationCartId: String) {
        guard let user, sourceCartId != destinationCartId else { return }
        removeFromCart(cartId: sourceCartId, productId: productId)
        guard let destIndex = carts.firstIndex(where: { $0.id == destinationCartId }) else { return }
        if let itemIndex = carts[destIndex].items.firstIndex(where: { $0.productId == productId }) {
            carts[destIndex].items[itemIndex].qty += qty
        } else {
            carts[destIndex].items.append(SharedCartItem(productId: productId, qty: qty, addedById: user.id, addedAt: Date().timeIntervalSince1970))
        }
        if carts[destIndex].isShared { broadcastSharedCarts() }
    }

    func checkoutCart(cartId: String) {
        guard let user, let index = carts.firstIndex(where: { $0.id == cartId }) else { return }
        carts[index].items = []
        if carts[index].isShared {
            broadcastSharedCarts()
            socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "checkout", productName: nil, qty: nil)
        }
    }

    private func notifyMutation(cartId: String, eventType: String, productName: String?, qty: Int?, actorId: String, actorName: String) {
        guard let cart = cartFor(cartId), cart.isShared else { return }
        broadcastSharedCarts()
        socket.sendEvent(actorId: actorId, actorName: actorName, eventType: eventType, productName: productName, qty: qty)
    }

    // MARK: - Cart badge

    var cartBadgeCount: Int {
        carts.reduce(0) { total, cart in total + cart.items.reduce(0) { $0 + $1.qty } }
    }

    // MARK: - Toasts

    func showToast(_ message: String) {
        let toast = Toast(message: message)
        toasts.removeAll()
        toasts.append(toast)
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            toasts.removeAll { $0.id == toast.id }
        }
    }
}
