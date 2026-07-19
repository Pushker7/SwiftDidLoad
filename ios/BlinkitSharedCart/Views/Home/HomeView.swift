import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = HomeViewModel()

    private var walletAmount: Int { appState.walletBalance }
    private var username: String { appState.user?.name ?? "Shopper" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Frosted glass header banner
                headerSection
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                // Search Bar with glass backdrop
                searchBarSection
                    .padding(.horizontal, 16)

                // Marketing Promo Banner with gradient & glass border
                promoBannerSection
                    .padding(.horizontal, 16)

                // Quick Categories selection
                categoriesSection
                    .padding(.horizontal, 16)

                // Shared Cart P2P Status Float
                if appState.hasConnections {
                    p2pStatusBanner
                        .padding(.horizontal, 16)
                }

                // Custom Product Rails (horizontal scrolling list cards)
                VStack(spacing: 22) {
                    ProductRail(title: "Fresh fruits & veggies 🍌", products: viewModel.filteredProducts(in: "fruits", appState: appState))
                    ProductRail(title: "Snacks & munchies 🍿", products: viewModel.filteredProducts(in: "snacks", appState: appState))
                    ProductRail(title: "Dairy & breakfast essentials 🥛", products: viewModel.filteredProducts(in: "dairy", appState: appState))
                }
                .padding(.bottom, 30)
            }
        }
        .background(
            ZStack {
                Theme.background
                // Ambient colorful glow at top-left simulating Liquid Glass
                RadialGradient(
                    colors: [Theme.primary.opacity(0.15), .clear],
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 320
                )
                .ignoresSafeArea()
            }
        )
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingAddressSheet) {
            addressSheetView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingWalletSheet) {
            walletSheetView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Location Pins
            Button {
                viewModel.showingAddressSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Blinkit in 23 mins")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        Text(viewModel.currentAddress)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Wallet Badge
            Button {
                viewModel.showingWalletSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.primary)
                    Text("₹\(walletAmount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // User Profile Shortcut
            avatar(name: username, hex: appState.user?.colorHex ?? memberColors[0], size: 36)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
        }
        .padding(12)
        .liquidGlassBackground()
    }

    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textSecondary)
                .font(.system(size: 16, weight: .bold))
            
            TextField("Search \"chocolate\" or \"milk\"", text: $viewModel.searchQuery)
                .font(.system(size: 14))
                .autocorrectionDisabled()
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .liquidGlassBackground(cornerRadius: 12)
    }

    private var promoBannerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Get ₹100 Cashback on Combos!")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "9A3412"))
                Text("Invite your family and shop together. Save big on fruits & pantry essentials.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "C2410C"))
            }
            Spacer()
            Text("🥑🍎")
                .font(.system(size: 38))
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFFBEB"), Color(hex: "FEF3C7").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(hex: "FEF3C7").opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var categoriesSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
            ForEach(appState.categories) { category in
                NavigationLink(destination: CategoryListView(initialCategoryId: category.id)) {
                    VStack(spacing: 8) {
                        Text(category.emoji)
                            .font(.system(size: 32))
                            .frame(width: 54, height: 54)
                            .background(.white.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        
                        Text(category.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .liquidGlassBackground(cornerRadius: 16)
    }

    private var p2pStatusBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.primary)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(Theme.primary.opacity(0.3), lineWidth: 4))
            
            Text("Connected to Home Cart")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            HStack(spacing: -4) {
                ForEach(appState.members.prefix(3)) { member in
                    avatar(name: member.name, hex: member.colorHex, size: 18)
                        .overlay(Circle().stroke(.white, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlassBackground(cornerRadius: 12)
    }

    private var walletSheetView: some View {
        VStack(spacing: 20) {
            Text("Blinkit Money")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 24)
            
            Text("₹\(walletAmount)")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(Theme.primary)
            
            HStack(spacing: 12) {
                walletQuickAddButton(amount: 100)
                walletQuickAddButton(amount: 500)
                walletQuickAddButton(amount: 1000)
            }
            
            Spacer()
        }
        .background(Theme.background)
    }

    private func walletQuickAddButton(amount: Int) -> some View {
        Button {
            viewModel.addMockWalletAmount(amount: amount, appState: appState)
        } label: {
            Text("+₹\(amount)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.primary.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var addressSheetView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Address")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 24)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                addressOptionRow(address: "Chhatarpur Farms, DLF Farms")
                addressOptionRow(address: "402, Sunrise Apartments, Gurugram")
                addressOptionRow(address: "102, Huda Metro Station Road, Sec 29")
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Theme.background)
    }

    private func addressOptionRow(address: String) -> some View {
        Button {
            viewModel.updateAddress(address: address, appState: appState)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.primary)
                
                Text(address)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if viewModel.currentAddress == address {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.primary)
                }
            }
            .padding(14)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }
}

struct ProductRail: View {
    let title: String
    let products: [Product]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(products) { product in
                        ProductCard(product: product)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
