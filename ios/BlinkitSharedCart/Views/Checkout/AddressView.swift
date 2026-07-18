import SwiftUI

struct OrderSummary {
    let itemCount: Int
    let total: Int
}

struct AddressView: View {
    @Environment(AppState.self) private var appState
    let cartId: String
    @State private var placedSummary: OrderSummary?

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Delivery address")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "house.fill")
                        .foregroundStyle(Theme.primary)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Home")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("402, Sunrise Apartments, Gurugram")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.primary)
                }
                .padding(14)
                .cardBackground()
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.primary, lineWidth: 1.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()

            Button {
                placeOrder()
            } label: {
                Text("Place order")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Choose address")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $placedSummary) { summary in
            SuccessView(summary: summary)
        }
    }

    private func placeOrder() {
        let items = appState.cartFor(cartId)?.items ?? []
        let subtotal = items.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + product.price * item.qty
        }
        let itemCount = items.reduce(0) { $0 + $1.qty }
        placedSummary = OrderSummary(itemCount: itemCount, total: CartMath.estTotal(subtotal: subtotal))
        appState.checkoutCart(cartId: cartId)
    }
}

extension OrderSummary: Identifiable, Hashable {
    var id: Int { itemCount * 1_000_003 + total }
}
