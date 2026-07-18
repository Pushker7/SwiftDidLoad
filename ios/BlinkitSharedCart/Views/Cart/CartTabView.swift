import SwiftUI

struct CartTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: CartTab = .personal

    var body: some View {
        VStack(spacing: 0) {
            if appState.hasConnections {
                CartToggle(selection: $selection)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if selection == .personal, let sharedCount = sharedItemCount, sharedCount > 0 {
                    Button {
                        withAnimation { selection = .shared }
                    } label: {
                        HStack {
                            Text("🏠 Home Cart has \(sharedCount) items →")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                        }
                        .padding(12)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                    .buttonStyle(.plain)
                }
            }

            if selection == .shared && appState.hasConnections {
                SharedCartView()
            } else {
                PersonalCartView()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Cart")
    }

    private var sharedItemCount: Int? {
        appState.sharedCart?.items.reduce(0) { $0 + $1.qty }
    }
}
