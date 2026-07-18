import SwiftUI

struct PersonalCartView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CartViewModel()

    private var subtotal: Int {
        appState.personalCart.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + product.price * item.qty
        }
    }

    private var itemCount: Int {
        appState.personalCart.reduce(0) { $0 + $1.qty }
    }

    var body: some View {
        Group {
            if appState.personalCart.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        deliveryNudgeHeader
                        
                        // Cart items list with Liquid Glass style
                        VStack(spacing: 0) {
                            ForEach(Array(appState.personalCart.enumerated()), id: \.element.id) { index, item in
                                if let product = appState.productFor(item.productId) {
                                    PersonalCartRow(product: product, qty: item.qty)
                                    if index < appState.personalCart.count - 1 {
                                        Divider().background(Theme.border.opacity(0.5))
                                    }
                                }
                            }
                        }
                        .liquidGlassBackground()
                        .padding(.horizontal, 16)

                        youMightAlsoLikeSection
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if !appState.personalCart.isEmpty {
                NavigationLink {
                    AddressView(cartType: .personal)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(itemCount) items · ₹\(CartMath.estTotal(subtotal: subtotal))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Delivery & taxes extra")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Select address at next step")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Theme.primary, Theme.primary.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Theme.primary.opacity(0.25), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var deliveryNudgeHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                if subtotal >= 199 {
                    Text("Free delivery in 15 minutes")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Shipment of \(itemCount) items")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("Add items worth ₹\(199 - subtotal) more for FREE delivery")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.offerText)
                    Text("Currently ₹\(CartMath.deliveryFee(subtotal: subtotal)) delivery fee applies")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .liquidGlassBackground()
        .padding(.horizontal, 16)
    }

    private var youMightAlsoLikeSection: some View {
        let currentProductIds = Set(appState.personalCart.map { $0.productId })
        let suggestions = appState.products.filter { !currentProductIds.contains($0.id) }.prefix(6)
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("You might also like")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions) { product in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.emoji)
                                .font(.system(size: 32))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                               .background(Color.white.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text(product.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)

                            Text(product.unit)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textSecondary)

                            HStack {
                                Text("₹\(product.price)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Button {
                                    appState.addToPersonalCart(productId: product.id)
                                    appState.showToast("Added to My Cart")
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Theme.primary)
                                        .padding(6)
                                        .background(Circle().stroke(Theme.primary, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                        .frame(width: 120)
                        .liquidGlassBackground()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🛍️")
                .font(.system(size: 56))
            Text("Your cart is empty")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Add items worth ₹199 to unlock free delivery.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            Spacer()
        }
    }
}

struct PersonalCartRow: View {
    @Environment(AppState.self) private var appState
    let product: Product
    let qty: Int

    var body: some View {
        HStack(spacing: 12) {
            // Product Emoji
            Text(product.emoji)
                .font(.system(size: 32))
                .padding(8)
                .background(Color.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Name & Sub-links
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                
                Text(product.unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                
                HStack(spacing: 12) {
                    // Move to wishlist
                    Button {
                        moveToWishlist()
                    } label: {
                        Text("Move to wishlist")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.blue)
                            .underline()
                    }
                    .buttonStyle(.plain)

                    // Move to Shared Cart
                    if appState.hasConnections {
                        Button {
                            moveToSharedCart()
                        } label: {
                            Text("Move to Shared Cart")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.primary)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            // Stepper & Pricing
            VStack(alignment: .trailing, spacing: 6) {
                QtyStepper(qty: qty) { newQty in
                    appState.setPersonalQty(productId: product.id, qty: newQty)
                }
                
                HStack(spacing: 4) {
                    Text("₹\(product.price * qty)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if product.mrp > product.price {
                        Text("₹\(product.mrp * qty)")
                            .font(.system(size: 10))
                            .strikethrough()
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    private func moveToWishlist() {
        // Remove from personal cart
        appState.setPersonalQty(productId: product.id, qty: 0)
        
        // Add to wishlist
        var list = UserDefaults.standard.stringArray(forKey: "wishlist") ?? []
        if !list.contains(product.id) {
            list.append(product.id)
            UserDefaults.standard.set(list, forKey: "wishlist")
        }
        appState.showToast("Moved to Liked Items")
    }

    private func moveToSharedCart() {
        // Move from personal to shared
        appState.setPersonalQty(productId: product.id, qty: 0)
        appState.addToSharedCart(productId: product.id)
        if qty > 1 {
            for _ in 1..<qty {
                appState.addToSharedCart(productId: product.id)
            }
        }
        appState.showToast("Moved to Shared Cart")
    }
}
