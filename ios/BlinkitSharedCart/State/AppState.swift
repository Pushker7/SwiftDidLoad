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

    var walletBalance: Int = 0 {
        didSet { UserDefaults.standard.set(walletBalance, forKey: "walletBalance") }
    }

    /// Single source of truth for the address book — Home, Profile and Checkout all read this.
    var savedAddresses: [String] = [] {
        didSet { UserDefaults.standard.set(savedAddresses, forKey: "savedAddresses") }
    }

    var selectedAddress: String = "" {
        didSet { UserDefaults.standard.set(selectedAddress, forKey: "selectedAddress") }
    }

    var selectedPaymentMethod: String = "Blinkit UPI Wallet" {
        didSet { UserDefaults.standard.set(selectedPaymentMethod, forKey: "selectedPaymentMethod") }
    }

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

        loadWalletAndAddresses()

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

    // MARK: - Wallet & addresses

    private func loadWalletAndAddresses() {
        walletBalance = UserDefaults.standard.integer(forKey: "walletBalance")

        let stored = UserDefaults.standard.stringArray(forKey: "savedAddresses") ?? []
        savedAddresses = stored.isEmpty
            ? ["Chhatarpur Farms, DLF Farms",
               "402, Sunrise Apartments, Gurugram",
               "102, Huda Metro Station Road, Sec 29"]
            : stored

        let storedSelection = UserDefaults.standard.string(forKey: "selectedAddress") ?? ""
        selectedAddress = savedAddresses.contains(storedSelection) ? storedSelection : (savedAddresses.first ?? "")

        if let method = UserDefaults.standard.string(forKey: "selectedPaymentMethod") {
            selectedPaymentMethod = method
        }
    }

    func addAddress(_ address: String) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !savedAddresses.contains(trimmed) else { return }
        savedAddresses.append(trimmed)
        selectedAddress = trimmed
    }

    func deleteAddress(_ address: String) {
        guard savedAddresses.count > 1 else { return }
        savedAddresses.removeAll { $0 == address }
        if selectedAddress == address {
            selectedAddress = savedAddresses.first ?? ""
        }
    }

    /// Spends as much of the wallet as the order total allows and returns the amount covered,
    /// so checkout can show "paid by Blinkit Money" vs. what's still payable.
    @discardableResult
    func redeemWallet(towards total: Int) -> Int {
        let applied = min(walletBalance, total)
        guard applied > 0 else { return 0 }
        walletBalance -= applied
        return applied
    }

    // MARK: - Connections

    func connect(code: String) async {
        connectError = nil
        guard user != nil else { return }
        socket.startBrowsing(targetCode: code)
        showToast("Searching for code \(code.uppercased())…")
    }

    private func setupSocketCallbacks() {
        socket.onState = { [weak self] incomingSharedCarts, _, incomingMembers in
            guard let self else { return }
            // Remember what the shared cart looked like before this snapshot lands — a
            // checkout broadcast arrives as (cleared cart, then event), so this is what
            // lets the non-paying members show the right order in their Live Activity.
            self.captureOrderSnapshot()

            // Set-reconciliation: the sender always broadcasts its FULL known shared-cart
            // set, so replacing our whole shared subset with theirs correctly propagates
            // adds, edits, AND deletes, while personal (non-shared) carts are untouched.
            self.carts.removeAll { $0.isShared }
            self.carts.append(contentsOf: incomingSharedCarts)
            self.members = incomingMembers
            if !self.carts.contains(where: { $0.id == self.activeCartId }) {
                self.activeCartId = self.carts.first?.id ?? ""
            }
            self.syncLiveActivity()
        }
        socket.onEvent = { [weak self] actorId, actorName, eventType, productName, qty in
            self?.handleEvent(actorId: actorId, actorName: actorName, eventType: eventType, productName: productName, qty: qty)
        }
        socket.onPeerConnected = { [weak self] peerUser in
            guard let self, let user = self.user else { return }
            self.members = [user, peerUser]
            // First-time connect: stand up a live shared cart automatically so both
            // sides immediately see items and totals sync, no manual setup needed.
            if !self.carts.contains(where: { $0.isShared }) {
                self.createCart(name: "Shared Cart", isShared: true)
            } else {
                self.broadcastSharedCarts()
            }
            self.socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "join", productName: nil, qty: nil)
            self.showToast("Connected with \(peerUser.name)! Shared Cart is live 🎉")
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
            showToast("🎉 \(actorName) placed an order")
            if let snapshot = lastOrderSnapshot {
                startDeliveryActivity(
                    cartId: snapshot.cartId,
                    cartName: snapshot.name,
                    itemCount: snapshot.itemCount,
                    total: snapshot.total,
                    placedBy: actorName
                )
            }
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
        let wasShared = cartFor(id)?.isShared ?? false
        carts.removeAll { $0.id == id }
        if activeCartId == id {
            activeCartId = carts.first?.id ?? ""
        }
        if wasShared { broadcastSharedCarts() }
    }

    /// Toggle a cart between personal and shared. Turning sharing on immediately
    /// broadcasts it so a connected peer sees the new list appear live; turning it
    /// off broadcasts too, so the peer's copy of that list disappears.
    func setShared(cartId: String, isShared: Bool) {
        guard let index = carts.firstIndex(where: { $0.id == cartId }) else { return }
        let wasShared = carts[index].isShared
        carts[index].isShared = isShared
        carts[index].memberIds = isShared ? members.map { $0.id } : []
        if isShared || wasShared { broadcastSharedCarts() }
    }

    /// Disconnects the peer and demotes every shared cart back to personal (kept locally, no data loss).
    func disconnectPeer() {
        members = []
        for index in carts.indices where carts[index].isShared {
            carts[index].isShared = false
            carts[index].memberIds = []
        }
        LiveActivityManager.shared.end()
    }

    /// Sends the full set of shared carts (including ones received from the peer earlier),
    /// so the receiver can do a correct set-reconciliation — including deletions.
    private func broadcastSharedCarts() {
        socket.sendCartState(carts: carts.filter { $0.isShared }, activeCartId: activeCartId, members: members)
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

        // Capture the order details before the cart is emptied, so the delivery
        // Live Activity can show what was actually ordered.
        let cart = carts[index]
        let itemCount = cart.items.reduce(0) { $0 + $1.qty }
        let subtotal = cart.items.reduce(0) { runningTotal, item in
            guard let product = productFor(item.productId) else { return runningTotal }
            return runningTotal + product.price * item.qty
        }

        carts[index].items = []
        if cart.isShared {
            broadcastSharedCarts()
            socket.sendEvent(actorId: user.id, actorName: user.name, eventType: "checkout", productName: nil, qty: nil)
            startDeliveryActivity(
                cartId: cart.id,
                cartName: cart.name,
                itemCount: itemCount,
                total: CartMath.estTotal(subtotal: subtotal),
                placedBy: "You"
            )
        }
    }

    private func notifyMutation(cartId: String, eventType: String, productName: String?, qty: Int?, actorId: String, actorName: String) {
        guard let cart = cartFor(cartId), cart.isShared else { return }
        broadcastSharedCarts()
        socket.sendEvent(actorId: actorId, actorName: actorName, eventType: eventType, productName: productName, qty: qty)

        let verb = eventType == "remove" ? "removed" : (eventType == "qty" ? "updated" : "added")
        syncLiveActivity(headline: productName.map { "\(actorName) \(verb) \($0)" } ?? "\(actorName) updated the cart")
    }

    // MARK: - Live Activity

    private struct OrderSnapshot {
        let cartId: String
        let name: String
        let itemCount: Int
        let total: Int
    }

    private var lastOrderSnapshot: OrderSnapshot?

    private func captureOrderSnapshot() {
        guard let cart = carts.first(where: { $0.isShared }) else { return }
        let itemCount = cart.items.reduce(0) { $0 + $1.qty }
        guard itemCount > 0 else { return }
        let subtotal = cart.items.reduce(0) { runningTotal, item in
            guard let product = productFor(item.productId) else { return runningTotal }
            return runningTotal + product.price * item.qty
        }
        lastOrderSnapshot = OrderSnapshot(
            cartId: cart.id,
            name: cart.name,
            itemCount: itemCount,
            total: CartMath.estTotal(subtotal: subtotal)
        )
    }

    /// Mirrors the first shared cart onto the lock screen / Dynamic Island. Runs on every
    /// member's device off their own synced state, so everyone sees changes — not just the payer.
    func syncLiveActivity(headline: String? = nil) {
        guard let cart = carts.first(where: { $0.isShared }), hasConnections else {
            LiveActivityManager.shared.endIfShopping()
            return
        }

        let itemCount = cart.items.reduce(0) { $0 + $1.qty }
        guard itemCount > 0 else {
            LiveActivityManager.shared.endIfShopping()
            return
        }

        let total = cart.items.reduce(0) { runningTotal, item in
            guard let product = productFor(item.productId) else { return runningTotal }
            return runningTotal + product.price * item.qty
        }

        LiveActivityManager.shared.sync(
            cartId: cart.id,
            phase: .shopping,
            cartName: cart.name,
            itemCount: itemCount,
            total: CartMath.estTotal(subtotal: total),
            headline: headline ?? "\(itemCount) items in \(cart.name)",
            memberInitials: members.map { String($0.name.prefix(1)).uppercased() }
        )
    }

    /// Switches the Live Activity to delivery tracking. Called on the device that placed the
    /// order and, via the broadcast `checkout` event, on every other member's device too.
    private func startDeliveryActivity(cartId: String, cartName: String, itemCount: Int, total: Int, placedBy: String) {
        guard itemCount > 0 else { return }
        LiveActivityManager.shared.sync(
            cartId: cartId,
            phase: .packing,
            cartName: cartName,
            itemCount: itemCount,
            total: total,
            headline: "\(placedBy) placed the order",
            memberInitials: members.map { String($0.name.prefix(1)).uppercased() },
            orderId: String(format: "BLK-%04d", Int.random(in: 0...9999)),
            deliveryETA: Date().addingTimeInterval(25 * 60)
        )
    }

    // MARK: - Cart badge

    var cartBadgeCount: Int {
        carts.reduce(0) { total, cart in total + cart.items.reduce(0) { $0 + $1.qty } }
    }

    // MARK: - Toasts

    func showToast(_ message: String) {
        toasts.removeAll()
        let toast = Toast(message: message)
        toasts.append(toast)
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            toasts.removeAll { $0.id == toast.id }
        }
    }
}
