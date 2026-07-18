import SwiftUI
import UIKit

struct MyCodeSheet: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Section 1: Your Code to Share
                VStack(spacing: 12) {
                    Text("Invite to Home Cart")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 8)

                    Text("Share this code with others so they can connect to your cart.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    Text(appState.user?.code ?? "")
                        .font(.system(size: 38, weight: .black, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(6)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.white.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))

                    Button {
                        UIPasteboard.general.string = appState.user?.code
                        appState.showToast("Code copied to clipboard!")
                    } label: {
                        Label("Copy Invite Code", systemImage: "doc.on.doc")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
                .padding(16)
                .liquidGlassBackground()
                
                // Section 2: Enter Partner Code to Connect
                VStack(spacing: 16) {
                    Text("Join a Friend's Cart")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Enter their 6-character code below to instantly link your shopping sessions.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    ConnectForm()
                }
                .padding(16)
                .liquidGlassBackground()
            }
            .padding(16)
        }
        .background(
            ZStack {
                Theme.background
                RadialGradient(
                    colors: [Theme.primary.opacity(0.08), .clear],
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 280
                )
                .ignoresSafeArea()
            }
        )
    }
}
