import SwiftUI
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var showingMyCode = false
    var showingSupport = false
    var showingPayments = false
    var showingWallet = false
    var showingAddressList = false
    var showingLikedItems = false
    var showingNameEdit = false
    var hideSensitive = false
    var newName = ""

    func saveName(appState: AppState) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            appState.updateName(name: trimmed)
            showingNameEdit = false
            appState.showToast("Profile name updated successfully!")
        }
    }

    func toggleSensitive(appState: AppState) {
        UserDefaults.standard.set(hideSensitive, forKey: "hideSensitive")
        appState.showToast(hideSensitive ? "Sensitive items hidden!" : "Sensitive items visible.")
    }
}
