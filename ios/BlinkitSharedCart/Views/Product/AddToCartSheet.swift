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

            VStack(spacing: 12) {
                optionButton(
                    emoji: "🛍️",
                    title: "My Cart",
                    subtitle: "Just for you, private"
                ) {
                    appState.addToPersonalCart(productId: product.id)
                    appState.showToast("Added to My Cart")
                    dismiss()
                }

                optionButton(
                    emoji: "👨‍👩‍👧",
                    title: "Shared Cart · Home Cart (live)",
                    subtitle: "Everyone sees it instantly"
                ) {
                    appState.addToSharedCart(productId: product.id)
                    appState.showToast("Added to Shared Cart")
                    dismiss()
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
