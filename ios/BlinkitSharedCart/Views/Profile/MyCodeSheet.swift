import SwiftUI
import UIKit

struct MyCodeSheet: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            Text("Invite to Home Cart")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 12)

            Text("Share this code — they enter it in Profile → Add a person")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(appState.user?.code ?? "")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .tracking(6)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .cardBackground()

            Button {
                UIPasteboard.general.string = appState.user?.code
                appState.showToast("Code copied")
            } label: {
                Label("Copy code", systemImage: "doc.on.doc")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Theme.background)
    }
}
