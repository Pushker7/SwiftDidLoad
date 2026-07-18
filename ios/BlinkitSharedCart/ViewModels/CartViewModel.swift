import SwiftUI
import Observation

@Observable
@MainActor
final class CartViewModel {
    // Shared state options
    var sortOption: SortOption = .recent
    var filterMemberId: String? = nil
    var showingSortSheet = false
    var showingSplitSheet = false
    var showingMyCodeSheet = false
    var showingAddProductSheet = false
    var showingDuplicatesSheet = false
    var expandedUsers: Set<String> = []

    func toggleUserExpansion(memberId: String) {
        if expandedUsers.contains(memberId) {
            expandedUsers.remove(memberId)
        } else {
            expandedUsers.insert(memberId)
        }
    }

    func isExpanded(memberId: String) -> Bool {
        expandedUsers.contains(memberId)
    }

    func sortedSharedItems(appState: AppState) -> [SharedCartItem] {
        let items = appState.sharedCart?.items ?? []
        var result = items
        
        if let filterMemberId {
            result = result.filter { $0.addedById == filterMemberId }
        }
        
        switch sortOption {
        case .recent:
            result.sort { $0.addedAt > $1.addedAt }
        case .priceLowHigh:
            result.sort {
                let p1 = appState.productFor($0.productId)?.price ?? 0
                let p2 = appState.productFor($1.productId)?.price ?? 0
                return p1 < p2
            }
        case .priceHighLow:
            result.sort {
                let p1 = appState.productFor($0.productId)?.price ?? 0
                let p2 = appState.productFor($1.productId)?.price ?? 0
                return p1 > p2
            }
        }
        return result
    }

    func duplicateProductIds(appState: AppState) -> [String] {
        let items = appState.sharedCart?.items ?? []
        let pids = items.map { $0.productId }
        let uniquePids = Set(pids)
        var duplicates: [String] = []
        for pid in uniquePids {
            let adders = Set(items.filter { $0.productId == pid }.map { $0.addedById })
            if adders.count > 1 {
                duplicates.append(pid)
            }
        }
        return duplicates
    }
}
