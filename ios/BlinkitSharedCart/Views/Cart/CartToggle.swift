import SwiftUI

enum CartTab {
    case personal, shared
}

struct CartToggle: View {
    @Binding var selection: CartTab

    var body: some View {
        HStack(spacing: 4) {
            segment("My Cart", tab: .personal)
            segment("Shared Cart", tab: .shared, showBadge: true)
        }
        .padding(4)
        .background(Theme.card)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
    }

    private func segment(_ title: String, tab: CartTab, showBadge: Bool = false) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selection = tab }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                if showBadge {
                    Text("NEW")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(selection == tab ? .white : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selection == tab ? Theme.primary : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
