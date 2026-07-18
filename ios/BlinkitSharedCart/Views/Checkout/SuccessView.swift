import SwiftUI

struct SuccessView: View {
    @Environment(\.goHome) private var goHome
    let summary: OrderSummary
    @State private var orderId = String(format: "BLK-%04d", Int.random(in: 0...9999))

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("✅")
                    .font(.system(size: 64))
                Text("Order placed!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(orderId)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)

                VStack(spacing: 2) {
                    Text("\(summary.itemCount) items")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Arriving in 25 mins")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.primary)
                }
                .padding(.top, 8)

                billDetailsCard
                    .padding(.top, 8)

                if !summary.shares.isEmpty {
                    splitSummaryCard
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    goHome()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }

    private var billDetailsCard: some View {
        VStack(spacing: 10) {
            Text("Bill details")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            billRow(label: "Item total", value: "₹\(summary.subtotal)")

            if summary.savings > 0 {
                billRow(label: "Savings", value: "-₹\(summary.savings)", valueColor: Theme.primary)
            }

            billRow(
                label: "Delivery fee",
                value: summary.deliveryFee == 0 ? "FREE" : "₹\(summary.deliveryFee)",
                valueColor: summary.deliveryFee == 0 ? Theme.primary : Theme.textPrimary
            )

            Divider().background(Theme.border)

            HStack {
                Text("Total paid")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("₹\(summary.total)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(16)
        .cardBackground()
    }

    private func billRow(label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(valueColor ?? Theme.textPrimary)
        }
    }

    private var splitSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Split summary")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 8) {
                ForEach(summary.shares) { share in
                    HStack(spacing: 10) {
                        avatar(name: share.name, hex: share.colorHex, size: 32)
                        Text(share.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("₹\(share.amount)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(10)
                    .background(share.name == "You" ? Theme.primary.opacity(0.1) : Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .cardBackground()
    }
}
