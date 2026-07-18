import SwiftUI

struct SplitPaymentSheet: View {
    @Environment(AppState.self) private var appState

    private var items: [SharedCartItem] { appState.sharedCart?.items ?? [] }

    private var cartTotal: Int {
        items.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + product.price * item.qty
        }
    }

    private func subtotal(for memberId: String) -> Int {
        items.filter { $0.addedById == memberId }.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + product.price * item.qty
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Split payment")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 12)

            VStack(spacing: 10) {
                ForEach(appState.members) { member in
                    let isYou = member.id == appState.user?.id
                    HStack(spacing: 12) {
                        avatar(name: member.name, hex: member.colorHex, size: 40)
                        Text(isYou ? "You" : member.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("₹\(subtotal(for: member.id))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(12)
                    .background(isYou ? Theme.primary.opacity(0.12) : Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isYou ? Theme.primary : Theme.border, lineWidth: 1))
                }
            }

            HStack {
                Text("Cart total")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("₹\(cartTotal)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(20)
        .background(Theme.background)
    }
}
