import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeaderCard
                actionsRow
                appSettingsCard
                yourInformationSection
            }
            .padding(16)
        }
        .background(
            ZStack {
                Theme.background
                RadialGradient(
                    colors: [Theme.primary.opacity(0.12), .clear],
                    center: .topTrailing,
                    startRadius: 5,
                    endRadius: 350
                )
                .ignoresSafeArea()
            }
        )
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $viewModel.showingMyCode) {
            MyCodeSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingSupport) {
            supportSheetView
        }
        .sheet(isPresented: $viewModel.showingPayments) {
            paymentsSheetView
        }
        .sheet(isPresented: $viewModel.showingWallet) {
            walletSheetView
        }
        .sheet(isPresented: $viewModel.showingAddressList) {
            addressSheetView
        }
        .sheet(isPresented: $viewModel.showingLikedItems) {
            likedItemsSheetView
        }
        .sheet(isPresented: $viewModel.showingNameEdit) {
            editNameSheetView
        }
        .onAppear {
            viewModel.newName = appState.user?.name ?? ""
            viewModel.hideSensitive = UserDefaults.standard.bool(forKey: "hideSensitive")
        }
    }

    private var profileHeaderCard: some View {
        HStack(spacing: 14) {
            avatar(name: appState.user?.name ?? "", hex: appState.user?.colorHex ?? memberColors[0], size: 52)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(appState.user?.name ?? "")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Button {
                        viewModel.showingNameEdit = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.primary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10))
                        Text("+91-9079901850")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "birthday.cake.fill")
                            .font(.system(size: 10))
                        Text("18 Mar 2007")
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .liquidGlassBackground()
    }

    private var actionsRow: some View {
        HStack(spacing: 12) {
            // Wallet Card
            actionCard(title: "Blinkit Money", icon: "wallet.pass.fill", color: .green) {
                viewModel.showingWallet = true
            }

            // Support Card
            actionCard(title: "Support", icon: "bubble.left.and.bubble.right.fill", color: .blue) {
                viewModel.showingSupport = true
            }

            // Payments Card
            actionCard(title: "Payments", icon: "creditcard.fill", color: .purple) {
                viewModel.showingPayments = true
            }
        }
    }

    private func actionCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .liquidGlassBackground()
        }
        .buttonStyle(.plain)
    }

    private var appSettingsCard: some View {
        VStack(spacing: 0) {
            // App Update
            Button {
                appState.showToast("You are on the latest version v18.70.0")
            } label: {
                HStack(spacing: 12) {
                    iconBadge(image: "arrow.down.circle.fill", color: .blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Update Available")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("v18.70.0")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            
            Divider().padding(.horizontal, 14).background(Theme.border.opacity(0.5))
            
            // Appearance Light Selection
            Button {
                appState.showToast("Blinkit is optimised for Light appearance")
            } label: {
                HStack(spacing: 12) {
                    iconBadge(image: "sun.max.fill", color: .orange)
                    Text("Appearance")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Light")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal, 14).background(Theme.border.opacity(0.5))

            // Hide sensitive items Toggle
            HStack(spacing: 12) {
                iconBadge(image: "eye.slash.fill", color: .red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hide sensitive items")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Sexual wellness, tobacco and sensitive items will be hidden")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $viewModel.hideSensitive)
                    .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
                    .onChange(of: viewModel.hideSensitive) { _, _ in
                        viewModel.toggleSensitive(appState: appState)
                    }
            }
            .padding(14)
        }
        .liquidGlassBackground()
    }

    private var yourInformationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR INFORMATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                infoRow(title: "Your wishlist / Liked items", icon: "heart.fill", badgeColor: .pink) {
                    viewModel.showingLikedItems = true
                }
                
                Divider().padding(.horizontal, 14).background(Theme.border.opacity(0.5))
                
                infoRow(title: "Address book", icon: "mappin.and.ellipse", badgeColor: .green) {
                    viewModel.showingAddressList = true
                }
                
                Divider().padding(.horizontal, 14).background(Theme.border.opacity(0.5))

                infoRow(title: "Add a person / Connect", icon: "person.badge.plus.fill", badgeColor: .blue) {
                    viewModel.showingMyCode = true
                }

                Divider().padding(.horizontal, 14).background(Theme.border.opacity(0.5))

                p2pCartSharingSection
            }
            .liquidGlassBackground()
        }
    }

    private func infoRow(title: String, icon: String, badgeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(image: icon, color: badgeColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private func iconBadge(image: String, color: Color) -> some View {
        Image(systemName: image)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 24, height: 24)
            .background(color.opacity(0.12))
            .clipShape(Circle())
    }

    private var p2pCartSharingSection: some View {
        let others = appState.members.filter { $0.id != appState.user?.id }
        
        return Group {
            if !others.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(others) { member in
                        HStack(spacing: 12) {
                            avatar(name: member.name, hex: member.colorHex, size: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Active in your Home Cart")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            
                            Button {
                                appState.disconnectPeer()
                                appState.showToast("Left the Home Cart successfully")
                            } label: {
                                Text("Leave")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                    }
                }
            }
        }
    }

    // MARK: - Mock Sheets

    private var supportSheetView: some View {
        VStack(spacing: 20) {
            Text("Blinkit Support")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 24)
            
            Text("💬 Chat Support is active")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.primary)
            
            Text("How can we help you today? Ask about active orders, payments, refunds, or Shared Cart options.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button {
                appState.showToast("Connecting you with an agent...")
            } label: {
                Text("Chat with us now")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .background(Theme.background)
    }

    private var paymentsSheetView: some View {
        VStack(spacing: 20) {
            Text("Saved Payment Methods")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 24)

            Text("Used as the default at checkout")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 12) {
                paymentOptionRow(title: "Visa Card ending in 4321", icon: "creditcard.fill")
                paymentOptionRow(title: "Apple Pay", icon: "applelogo")
                paymentOptionRow(title: "Blinkit UPI Wallet", icon: "indianrupeesign.circle.fill")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Theme.background)
    }

    private func paymentOptionRow(title: String, icon: String) -> some View {
        let isSelected = appState.selectedPaymentMethod == title
        return Button {
            appState.selectedPaymentMethod = title
            appState.showToast("\(title) set as default")
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.primary)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
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

    private var walletSheetView: some View {
        VStack(spacing: 20) {
            Text("Blinkit Money Wallet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 24)
            
            Text("₹\(appState.walletBalance)")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Theme.primary)
            
            Button {
                appState.walletBalance += 500
                appState.showToast("Added mockup ₹500 successfully!")
            } label: {
                Text("Add Mock ₹500")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Theme.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .background(Theme.background)
    }

    private var addressSheetView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Saved Addresses")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    viewModel.showingAddAddress = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(appState.savedAddresses, id: \.self) { address in
                        addressDetailRow(address: address)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(Theme.background)
        .alert("Add address", isPresented: $viewModel.showingAddAddress) {
            TextField("Flat, street, area", text: $viewModel.newAddress)
            Button("Cancel", role: .cancel) { viewModel.newAddress = "" }
            Button("Save") {
                appState.addAddress(viewModel.newAddress)
                viewModel.newAddress = ""
                appState.showToast("Address added!")
            }
        }
    }

    private func addressDetailRow(address: String) -> some View {
        let isSelected = appState.selectedAddress == address
        return Button {
            appState.selectedAddress = address
            appState.showToast("Delivery address updated!")
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Theme.primary : Theme.textSecondary)
                Text(address)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.primary)
                }
                if appState.savedAddresses.count > 1 {
                    Button {
                        appState.deleteAddress(address)
                        appState.showToast("Address removed")
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
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

    private var likedItemsSheetView: some View {
        let likedIds = UserDefaults.standard.stringArray(forKey: "wishlist") ?? []
        let likedProducts = appState.products.filter { likedIds.contains($0.id) }
        
        return VStack(spacing: 16) {
            Text("Liked Items")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 20)
            
            if likedProducts.isEmpty {
                VStack(spacing: 8) {
                    Text("❤️").font(.system(size: 40))
                    Text("No liked items yet. Tap heart icon on products!")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(likedProducts) { product in
                            HStack(spacing: 12) {
                                Text(product.emoji).font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("₹\(product.price)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Button {
                                    if let cart = appState.activeCart {
                                        appState.addToCart(cartId: cart.id, productId: product.id)
                                        appState.showToast("Added to \(cart.name)!")
                                    }
                                } label: {
                                    Text("Add")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Theme.primary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .cardBackground()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(Theme.background)
    }

    private var editNameSheetView: some View {
        VStack(spacing: 20) {
            Text("Edit Profile Name")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 24)
            
            TextField("Name", text: $viewModel.newName)
                .padding(12)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                .padding(.horizontal, 24)
            
            Button {
                viewModel.saveName(appState: appState)
            } label: {
                Text("Save Changes")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Theme.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .background(Theme.background)
    }
}
