import SwiftUI

struct AddToCartSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let product: Product

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Text(product.emoji).font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(product.unit) · ₹\(product.price)")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(appState.carts) { cart in
                        optionButton(
                            emoji: cart.isShared ? "👨‍👩‍👧" : "🛍️",
                            title: cart.name,
                            subtitle: cart.isShared ? "Everyone sees it instantly" : "Just for you, private"
                        ) {
                            appState.addToCart(cartId: cart.id, productId: product.id)
                            appState.showToast("Added to \(cart.name)")
                            dismiss()
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .background(Theme.background)
    }

    private func optionButton(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
            .cardBackground()
        }
    }
}
