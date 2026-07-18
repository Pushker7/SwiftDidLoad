import SwiftUI

struct FreeDeliveryNudge: View {
    let subtotal: Int
    private let threshold = 199

    var body: some View {
        Group {
            if subtotal >= threshold {
                Text("🎉 FREE delivery unlocked")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.primary)
            } else {
                Text("Add items worth ₹\(threshold - subtotal) more for FREE delivery")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.offerText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.offerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
    }
}

/// Label-only bottom bar; wrap in a `NavigationLink` at the call site to navigate on tap.
struct TotalBar: View {
    let itemCount: Int
    let total: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Est. total (\(itemCount) items)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                Text("₹\(total)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Text("Choose address")
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(Theme.card)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
    }
}

enum CartMath {
    static func deliveryFee(subtotal: Int) -> Int {
        subtotal < 199 ? 25 : 0
    }

    static func estTotal(subtotal: Int) -> Int {
        subtotal + deliveryFee(subtotal: subtotal)
    }
}
