import SwiftUI

struct ConnectForm: View {
    @Environment(AppState.self) private var appState
    @State private var code = ""
    @State private var isConnecting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add a person")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 10) {
                TextField("", text: $code, prompt: Text("6-char code").foregroundStyle(Theme.textSecondary))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .foregroundStyle(Theme.textPrimary)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .padding(12)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.uppercased().prefix(6))
                    }

                Button {
                    connect()
                } label: {
                    if isConnecting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Connect")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Theme.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(code.count != 6 || isConnecting)
                .opacity(code.count != 6 ? 0.5 : 1)
            }

            if let error = appState.connectError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .cardBackground()
    }

    private func connect() {
        isConnecting = true
        Task {
            await appState.connect(code: code)
            isConnecting = false
            if appState.connectError == nil { code = "" }
        }
    }
}
