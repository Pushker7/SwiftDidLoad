import SwiftUI

struct MemberShare: Identifiable, Hashable {
    let id: String
    let name: String
    let colorHex: String
    let amount: Int
}

struct OrderSummary {
    let itemCount: Int
    let subtotal: Int
    let savings: Int
    let deliveryFee: Int
    let total: Int
    /// Amount covered by Blinkit Money at checkout.
    let walletApplied: Int
    /// What's still due after the wallet is applied.
    let amountPayable: Int
    let address: String
    let paymentMethod: String
    /// Per-member item cost, splitwise-style. Empty for personal (non-shared) carts.
    let shares: [MemberShare]
}

struct AddressView: View {
    @Environment(AppState.self) private var appState
    let cartId: String
    @State private var placedSummary: OrderSummary?
    @State private var showingAddAddress = false
    @State private var newAddress = ""

    private var subtotal: Int {
        appState.cartFor(cartId)?.items.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + product.price * item.qty
        } ?? 0
    }

    private var orderTotal: Int { CartMath.estTotal(subtotal: subtotal) }
    private var walletApplied: Int { min(appState.walletBalance, orderTotal) }
    private var amountPayable: Int { orderTotal - walletApplied }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    addressSection
                    if appState.walletBalance > 0 { walletSection }
                    paymentSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            placeOrderBar
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Choose address")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $placedSummary) { summary in
            SuccessView(summary: summary)
        }
        .alert("Add address", isPresented: $showingAddAddress) {
            TextField("Flat, street, area", text: $newAddress)
            Button("Cancel", role: .cancel) { newAddress = "" }
            Button("Save") {
                appState.addAddress(newAddress)
                newAddress = ""
                appState.showToast("Address added!")
            }
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Delivery address")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    showingAddAddress = true
                } label: {
                    Label("Add new", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                ForEach(appState.savedAddresses, id: \.self) { address in
                    addressRow(address)
                }
            }
        }
    }

    private func addressRow(_ address: String) -> some View {
        let isSelected = appState.selectedAddress == address
        return Button {
            appState.selectedAddress = address
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "house.fill")
                    .foregroundStyle(isSelected ? Theme.primary : Theme.textSecondary)
                    .padding(.top, 2)
                Text(address)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.primary)
                }
            }
            .padding(14)
            .cardBackground()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.primary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var walletSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Blinkit Money applied")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Balance ₹\(appState.walletBalance)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("-₹\(walletApplied)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.primary)
        }
        .padding(14)
        .cardBackground()
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Paying with")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.primary)
                Text(appState.selectedPaymentMethod)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("Change in Profile")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
            .cardBackground()
        }
    }

    private var placeOrderBar: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("₹\(amountPayable)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if walletApplied > 0 {
                        Text("₹\(walletApplied) paid by Blinkit Money")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.primary)
                    } else {
                        Text("Total payable")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Button {
                    placeOrder()
                } label: {
                    Text("Place order")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
    }

    private func placeOrder() {
        guard let cart = appState.cartFor(cartId) else { return }
        let items = cart.items

        func cost(of matching: [SharedCartItem]) -> Int {
            matching.reduce(0) { total, item in
                guard let product = appState.productFor(item.productId) else { return total }
                return total + product.price * item.qty
            }
        }

        let subtotal = cost(of: items)
        let savings = items.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + (product.mrp - product.price) * item.qty
        }
        let itemCount = items.reduce(0) { $0 + $1.qty }
        let deliveryFee = CartMath.deliveryFee(subtotal: subtotal)
        let total = CartMath.estTotal(subtotal: subtotal)

        var shares: [MemberShare] = []
        if cart.isShared {
            shares = appState.members.compactMap { member in
                let amount = cost(of: items.filter { $0.addedById == member.id })
                guard amount > 0 else { return nil }
                let name = member.id == appState.user?.id ? "You" : member.name
                return MemberShare(id: member.id, name: name, colorHex: member.colorHex, amount: amount)
            }
        }

        // Spend the wallet before the cart is cleared so the receipt reflects the real charge.
        let applied = appState.redeemWallet(towards: total)

        placedSummary = OrderSummary(
            itemCount: itemCount,
            subtotal: subtotal,
            savings: savings,
            deliveryFee: deliveryFee,
            total: total,
            walletApplied: applied,
            amountPayable: total - applied,
            address: appState.selectedAddress,
            paymentMethod: appState.selectedPaymentMethod,
            shares: shares
        )
        appState.checkoutCart(cartId: cartId)
    }
}

extension OrderSummary: Identifiable, Hashable {
    var id: Int { itemCount * 1_000_003 + total }
}
