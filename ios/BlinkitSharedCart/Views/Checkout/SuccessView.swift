import SwiftUI

struct SuccessView: View {
    let summary: OrderSummary
    @State private var orderId = String(format: "BLK-%04d", Int.random(in: 0...9999))

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("✅")
                .font(.system(size: 64))
            Text("Order placed!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(orderId)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 6) {
                Text("\(summary.itemCount) items · ₹\(summary.total)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Arriving in 25 mins")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primary)
            }
            .padding(16)
            .cardBackground()
            .padding(.horizontal, 40)
            .padding(.top, 12)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
