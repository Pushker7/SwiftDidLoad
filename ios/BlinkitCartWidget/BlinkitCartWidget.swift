import ActivityKit
import SwiftUI
import WidgetKit

@main
struct BlinkitCartWidgetBundle: WidgetBundle {
    var body: some Widget {
        BlinkitCartLiveActivity()
    }
}

private enum WidgetTheme {
    static let green = Color(red: 0x0C / 255, green: 0x83 / 255, blue: 0x1F / 255)
    static let amber = Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x06 / 255)
}

private extension BlinkitCartAttributes.ContentState {
    var statusText: String {
        switch phase {
        case .shopping: return "Shared cart"
        case .packing: return "Packing your order"
        case .onTheWay: return "On the way"
        case .delivered: return "Delivered"
        }
    }

    var symbol: String {
        switch phase {
        case .shopping: return "cart.fill"
        case .packing: return "shippingbox.fill"
        case .onTheWay: return "bicycle"
        case .delivered: return "checkmark.seal.fill"
        }
    }

    var tint: Color {
        phase == .shopping ? WidgetTheme.green : WidgetTheme.amber
    }
}

struct BlinkitCartLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BlinkitCartAttributes.self) { context in
            lockScreenView(context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.cartName)
                            .font(.caption)
                            .foregroundStyle(.white)
                    } icon: {
                        Image(systemName: context.state.symbol)
                            .foregroundStyle(context.state.tint)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let eta = context.state.deliveryETA {
                        Text(timerInterval: Date()...eta, countsDown: true)
                            .font(.caption.monospacedDigit())
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(context.state.tint)
                            .frame(maxWidth: 64)
                    } else {
                        Text("₹\(context.state.total)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.headline)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                        initialsRow(context.state.memberInitials)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.symbol)
                    .foregroundStyle(context.state.tint)
            } compactTrailing: {
                if let eta = context.state.deliveryETA {
                    Text(timerInterval: Date()...eta, countsDown: true)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(context.state.tint)
                        .frame(maxWidth: 44)
                } else {
                    Text("\(context.state.itemCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(context.state.tint)
                }
            } minimal: {
                Image(systemName: context.state.symbol)
                    .foregroundStyle(context.state.tint)
            }
        }
    }

    private func lockScreenView(_ state: BlinkitCartAttributes.ContentState) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(state.tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: state.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(state.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(state.statusText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                Text(state.headline)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(state.itemCount) items · ₹\(state.total)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    if !state.orderId.isEmpty {
                        Text(state.orderId)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 6) {
                if let eta = state.deliveryETA {
                    Text(timerInterval: Date()...eta, countsDown: true)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(state.tint)
                        .frame(maxWidth: 74)
                }
                initialsRow(state.memberInitials)
            }
        }
        .padding(16)
    }

    private func initialsRow(_ initials: [String]) -> some View {
        HStack(spacing: -6) {
            ForEach(Array(initials.prefix(4).enumerated()), id: \.offset) { _, initial in
                Text(initial)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(WidgetTheme.green))
                    .overlay(Circle().stroke(.black.opacity(0.6), lineWidth: 1.5))
            }
        }
    }
}
