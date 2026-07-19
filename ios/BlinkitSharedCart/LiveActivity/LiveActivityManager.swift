import ActivityKit
import Foundation

/// Owns the single in-flight Live Activity for this device.
///
/// Every member drives their own activity from their own (P2P-synced) AppState, so no
/// push tokens or server are involved — when the shared cart changes on one phone, the
/// other phone's AppState updates and its Live Activity refreshes locally.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<BlinkitCartAttributes>?
    private var currentPhase: BlinkitOrderPhase?

    private var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Starts the activity if needed, otherwise updates it in place.
    func sync(
        cartId: String,
        phase: BlinkitOrderPhase,
        cartName: String,
        itemCount: Int,
        total: Int,
        headline: String,
        memberInitials: [String],
        orderId: String = "",
        deliveryETA: Date? = nil
    ) {
        guard isEnabled else { return }

        let state = BlinkitCartAttributes.ContentState(
            phase: phase,
            cartName: cartName,
            itemCount: itemCount,
            total: total,
            headline: headline,
            memberInitials: memberInitials,
            orderId: orderId,
            deliveryETA: deliveryETA
        )

        // Once an order is in flight the delivery countdown owns the activity — an
        // emptied cart must not tear it down.
        let staleDate = deliveryETA?.addingTimeInterval(15 * 60)

        if let activity, activity.attributes.cartId == cartId {
            currentPhase = phase
            Task { await activity.update(ActivityContent(state: state, staleDate: staleDate)) }
            return
        }

        // A different cart took over — retire the old activity before starting the new one.
        if activity != nil { endImmediately() }

        do {
            activity = try Activity.request(
                attributes: BlinkitCartAttributes(cartId: cartId),
                content: ActivityContent(state: state, staleDate: staleDate),
                pushType: nil
            )
            currentPhase = phase
        } catch {
            activity = nil
            currentPhase = nil
        }
    }

    /// Ends only a still-shopping activity. Used when a shared cart empties — if an order
    /// has already been placed, the delivery activity is left running.
    func endIfShopping() {
        guard currentPhase == nil || currentPhase == .shopping else { return }
        endImmediately()
    }

    func end() {
        endImmediately()
    }

    private func endImmediately() {
        guard let current = activity else { return }
        activity = nil
        currentPhase = nil
        Task { await current.end(nil, dismissalPolicy: .immediate) }
    }
}
