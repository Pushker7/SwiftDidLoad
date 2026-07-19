import ActivityKit
import Foundation

/// Which stage of the shared-cart journey the Live Activity is showing.
enum BlinkitOrderPhase: String, Codable, Hashable {
    case shopping   // cart is open, members are adding items
    case packing    // order placed, being packed
    case onTheWay   // rider en route
    case delivered
}

/// Shared between the app and the widget extension. Every member of a shared cart
/// runs their own local Live Activity, driven by their own synced AppState — so
/// cart changes and delivery updates show on everyone's lock screen, not just the
/// person who paid.
struct BlinkitCartAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: BlinkitOrderPhase
        var cartName: String
        var itemCount: Int
        var total: Int
        /// Short human line, e.g. "Priya added Amul Milk" or "Arriving soon".
        var headline: String
        /// First initial of each member, for the stacked avatars.
        var memberInitials: [String]
        var orderId: String
        /// When set, the widget renders a live countdown without needing app updates.
        var deliveryETA: Date?
    }

    var cartId: String
}
