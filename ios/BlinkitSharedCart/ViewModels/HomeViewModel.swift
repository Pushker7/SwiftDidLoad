import SwiftUI
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var searchQuery: String = ""
    var showingWalletSheet: Bool = false
    var showingAddressSheet: Bool = false
    var currentAddress: String = "Chhatarpur Farms, DLF Farms"
    var walletAmountText: String = ""
    
    func addMockWalletAmount(amount: Int, appState: AppState) {
        appState.walletBalance += amount
        appState.showToast("Added ₹\(amount) to Wallet!")
    }
    
    func updateAddress(address: String, appState: AppState) {
        currentAddress = address
        showingAddressSheet = false
        appState.showToast("Delivery address updated!")
    }
    
    func filteredProducts(in categoryId: String, appState: AppState) -> [Product] {
        let categoryProducts = appState.products.filter { $0.category == categoryId }
        if searchQuery.isEmpty {
            return categoryProducts
        }
        return categoryProducts.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }
}
