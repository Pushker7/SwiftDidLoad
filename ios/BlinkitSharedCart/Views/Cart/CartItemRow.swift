import SwiftUI

struct CartItemRow: View {
    @Environment(AppState.self) private var appState
    let cart: Cart
    let item: SharedCartItem
    let product: Product

    private var adder: User? { appState.memberFor(item.addedById) }
    private var isYou: Bool { item.addedById == appState.user?.id }
    private var otherCarts: [Cart] { appState.carts.filter { $0.id != cart.id } }

    var body: some View {
        HStack(spacing: 0) {
            // Left color-coded indicator representing the adder
            Rectangle()
                .fill(Color(hex: adder?.colorHex ?? memberColors[0]))
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            HStack(alignment: .center, spacing: 12) {
                // Product Emoji
                Text(product.emoji)
                    .font(.system(size: 28))
                    .padding(8)
                    .background(Color(hex: "F8FAFC"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Info details
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    
                    Text(product.unit)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)

//                    HStack(spacing: 4) {
//                        avatar(name: adder?.name ?? "?", hex: adder?.colorHex ?? memberColors[0], size: 14)
//                       // Text("Added by \(isYou ? "You" : adder?.name ?? "?")")
//                           // .font(.system(size: 10, weight: .bold))
//                    }
//                    .foregroundStyle(Color(hex: adder?.colorHex ?? memberColors[0]))
//                    .padding(.horizontal, 6)
//                    .padding(.vertical, 2)
//                    .background(Color(hex: adder?.colorHex ?? memberColors[0]).opacity(0.1))
//                    .clipShape(Capsule())
                }

                Spacer()

                // Actions and Pricing
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 8) {
                        QtyStepper(qty: item.qty) { newQty in
                            appState.setQty(cartId: cart.id, productId: product.id, qty: newQty)
                        }

                        Menu {
                            ForEach(otherCarts) { destination in
                                Button("Move to \(destination.name)") {
                                    appState.moveItem(productId: product.id, qty: item.qty, from: cart.id, to: destination.id)
                                }
                            }
                            Button("Remove item", role: .destructive) {
                                appState.removeFromCart(cartId: cart.id, productId: product.id)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 4) {
                        Text("₹\(product.price * item.qty)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        if product.mrp > product.price {
                            Text("₹\(product.mrp * item.qty)")
                                .font(.system(size: 10))
                                .strikethrough()
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
    }
}
