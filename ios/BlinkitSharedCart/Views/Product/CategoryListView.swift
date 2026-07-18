import SwiftUI

struct CategoryListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CategoryListViewModel()

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar selector with frosted glass look
            categorySidebar
                .frame(width: 86)
                .background(.ultraThinMaterial.opacity(0.8))
                .overlay(Rectangle().frame(width: 1).foregroundStyle(Theme.border), alignment: .trailing)

            // Right product browser panel
            VStack(spacing: 12) {
                searchAndFilterHeader
                
                let products = viewModel.sortedProducts(appState: appState)
                
                if products.isEmpty {
                    emptyResultState
                } else {
                    productGrid(products)
                }
            }
            .padding(.top, 10)
            .background(Theme.background)
        }
        .navigationTitle("Vegetables & Fruits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var categorySidebar: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(appState.categories) { category in
                    let isActive = (viewModel.selectedCategoryId ?? appState.categories.first?.id) == category.id
                    
                    Button {
                        viewModel.selectCategory(category.id)
                    } label: {
                        VStack(spacing: 6) {
                            Text(category.emoji)
                                .font(.system(size: 24))
                                .frame(width: 46, height: 46)
                                .background(isActive ? Theme.primary.opacity(0.12) : Color.white.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isActive ? Theme.primary.opacity(0.3) : Color.clear, lineWidth: 1))
                            
                            Text(category.label)
                                .font(.system(size: 9, weight: isActive ? .black : .medium))
                                .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isActive ? Color.white.opacity(0.4) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Divider().background(Theme.border.opacity(0.5))
                }
            }
        }
    }

    private var searchAndFilterHeader: some View {
        VStack(spacing: 10) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.system(size: 14))
                
                TextField("Search in category...", text: $viewModel.searchQuery)
                    .font(.system(size: 13))
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .liquidGlassBackground(cornerRadius: 10)
            .padding(.horizontal, 12)

            // Sort & Filter chips
            HStack(spacing: 8) {
                // Liked filter
                Button {
                    viewModel.showLikedOnly.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.showLikedOnly ? "heart.fill" : "heart")
                            .font(.system(size: 10, weight: .bold))
                        Text("Liked")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(viewModel.showLikedOnly ? .pink : Theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(viewModel.showLikedOnly ? Color.pink.opacity(0.1) : Color.white.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(viewModel.showLikedOnly ? Color.pink.opacity(0.3) : Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                // Sort cycling
                Button {
                    viewModel.cycleSort()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 9))
                        Text(sortLabel(for: viewModel.currentSort))
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(viewModel.currentSort == .none ? Theme.textPrimary : Theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(viewModel.currentSort == .none ? Color.white.opacity(0.4) : Theme.primary.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(viewModel.currentSort == .none ? Theme.border : Theme.primary.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 12)
        }
    }

    private func sortLabel(for sort: CategoryListViewModel.CategorySort) -> String {
        switch sort {
        case .none:
            return "Sort"
        case .priceLowHigh:
            return "Price: Low to High"
        case .priceHighLow:
            return "Price: High to Low"
        }
    }

    private var emptyResultState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("🔍")
                .font(.system(size: 36))
            Text("No products found")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Try searching for something else or clear filter.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func productGrid(_ products: [Product]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 12) {
                ForEach(products) { product in
                    ProductCard(product: product)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
    }
}
