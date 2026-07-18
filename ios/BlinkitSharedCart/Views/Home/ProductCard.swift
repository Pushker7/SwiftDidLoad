import SwiftUI

struct ProductCard: View {
    @Environment(AppState.self) private var appState
    let product: Product
    
    @State private var showingAddSheet = false
    @State private var isLiked = false

    private var personalQty: Int {
        appState.personalCart.first { $0.productId == product.id }?.qty ?? 0
    }

    private var sharedQty: Int {
        appState.sharedCart?.items.first { $0.productId == product.id }?.qty ?? 0
    }

    private var totalQty: Int {
        personalQty + sharedQty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top Image / Emoji section with wishlist overlay
            ZStack(alignment: .topTrailing) {
                // Background card gray for image
                VStack {
                    Text(product.emoji)
                        .font(.system(size: 44))
                        .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .background(Color(hex: "F8FAFC"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Wishlist like button
                Button {
                    toggleWishlist()
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isLiked ? .red : Theme.textSecondary)
                        .padding(6)
                        .background(Circle().fill(.white).shadow(color: .black.opacity(0.1), radius: 2))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            // Name
            Text(product.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .frame(height: 34, alignment: .top)

            // Weight & Delivery time info
            HStack {
                Text(product.unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                    Text("14m")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Theme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Price & Add button row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("₹\(product.price)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if product.mrp > product.price {
                        Text("₹\(product.mrp)")
                            .font(.system(size: 10, weight: .medium))
                            .strikethrough()
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                // Adaptive Add Button / Stepper
                if totalQty > 0 {
                    stepperControl
                } else {
                    addButton
                }
            }
        }
        .padding(10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
        .onAppear {
            checkWishlist()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddToCartSheet(product: product)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var addButton: some View {
        Button {
            addTapped()
        } label: {
            Text("ADD")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.primary, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var stepperControl: some View {
        HStack(spacing: 8) {
            Button {
                decrementQty()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Text("\(totalQty)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(minWidth: 12)

            Button {
                incrementQty()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Theme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func addTapped() {
        if appState.hasConnections {
            showingAddSheet = true
        } else {
            appState.addToPersonalCart(productId: product.id)
            appState.showToast("Added to My Cart")
        }
    }

    private func incrementQty() {
        if sharedQty > 0 {
            appState.addToSharedCart(productId: product.id)
        } else {
            appState.addToPersonalCart(productId: product.id)
        }
        appState.showToast("Added to cart")
    }

    private func decrementQty() {
        if personalQty > 0 {
            appState.setPersonalQty(productId: product.id, qty: personalQty - 1)
        } else if sharedQty > 0 {
            appState.setSharedQty(productId: product.id, qty: sharedQty - 1)
        }
        appState.showToast("Removed from cart")
    }

    private func toggleWishlist() {
        var list = UserDefaults.standard.stringArray(forKey: "wishlist") ?? []
        if isLiked {
            list.removeAll { $0 == product.id }
            isLiked = false
            appState.showToast("Removed from Liked Items")
        } else {
            list.append(product.id)
            isLiked = true
            appState.showToast("Added to Liked Items")
        }
        UserDefaults.standard.set(list, forKey: "wishlist")
    }

    private func checkWishlist() {
        let list = UserDefaults.standard.stringArray(forKey: "wishlist") ?? []
        isLiked = list.contains(product.id)
    }
}
