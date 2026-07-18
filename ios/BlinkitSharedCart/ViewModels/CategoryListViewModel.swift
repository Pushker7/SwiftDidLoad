import SwiftUI
import Observation

@Observable
@MainActor
final class CategoryListViewModel {
    var selectedCategoryId: String?
    var searchQuery: String = ""
    var showLikedOnly: Bool = false
    var currentSort: CategorySort = .none

    enum CategorySort {
        case none
        case priceLowHigh
        case priceHighLow
    }

    func selectCategory(_ categoryId: String) {
        selectedCategoryId = categoryId
    }

    func isProductLiked(_ productId: String) -> Bool {
        let wishlist = UserDefaults.standard.stringArray(forKey: "wishlist") ?? []
        return wishlist.contains(productId)
    }

    func toggleLike(for product: Product, appState: AppState) {
        var wishlist = UserDefaults.standard.stringArray(forKey: "wishlist") ?? []
        if wishlist.contains(product.id) {
            wishlist.removeAll { $0 == product.id }
            appState.showToast("Removed from wishlist")
        } else {
            wishlist.append(product.id)
            appState.showToast("Added to wishlist")
        }
        UserDefaults.standard.set(wishlist, forKey: "wishlist")
    }

    func sortedProducts(appState: AppState) -> [Product] {
        guard let activeCat = selectedCategoryId ?? appState.categories.first?.id else {
            return []
        }
        
        var list = appState.products.filter { $0.category == activeCat }
        
        if showLikedOnly {
            let wishlist = UserDefaults.standard.stringArray(forKey: "wishlist") ?? []
            list = list.filter { wishlist.contains($0.id) }
        }
        
        if !searchQuery.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        switch currentSort {
        case .none:
            break
        case .priceLowHigh:
            list.sort { $0.price < $1.price }
        case .priceHighLow:
            list.sort { $0.price > $1.price }
        }
        
        return list
    }

    func cycleSort() {
        switch currentSort {
        case .none:
            currentSort = .priceLowHigh
        case .priceLowHigh:
            currentSort = .priceHighLow
        case .priceHighLow:
            currentSort = .none
        }
    }
}
