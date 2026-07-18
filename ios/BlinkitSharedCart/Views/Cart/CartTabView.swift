import SwiftUI

struct CartTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showingNewCart = false

    var body: some View {
        VStack(spacing: 0) {
            CartPicker(showingNewCart: $showingNewCart)
                .padding(.top, 12)

            if let cart = appState.activeCart {
                if cart.isShared {
                    SharedCartView(cart: cart)
                } else {
                    PersonalCartView(cart: cart)
                }
            } else {
                Spacer()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Cart")
        .sheet(isPresented: $showingNewCart) {
            NewCartSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct CartPicker: View {
    @Environment(AppState.self) private var appState
    @Binding var showingNewCart: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(appState.carts) { cart in
                    chip(for: cart)
                }
                Button {
                    showingNewCart = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .frame(width: 32, height: 32)
                        .background(Theme.primary.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(for cart: Cart) -> some View {
        let isActive = cart.id == appState.activeCartId
        let count = cart.items.reduce(0) { $0 + $1.qty }
        return Button {
            appState.activeCartId = cart.id
        } label: {
            HStack(spacing: 6) {
                if cart.isShared {
                    Image(systemName: "person.2.fill").font(.system(size: 10))
                }
                Text(cart.name).font(.system(size: 13, weight: .semibold))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isActive ? Color.white.opacity(0.3) : Theme.primary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isActive ? .white : Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Theme.primary : Theme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isActive ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if appState.hasConnections {
                if cart.isShared {
                    Button("Make private") {
                        appState.setShared(cartId: cart.id, isShared: false)
                    }
                } else {
                    Button("Share this list") {
                        appState.setShared(cartId: cart.id, isShared: true)
                    }
                }
            }
            if appState.carts.count > 1 {
                Button("Delete list", role: .destructive) {
                    appState.deleteCart(id: cart.id)
                }
            }
        }
    }
}

private struct NewCartSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isShared = false

    var body: some View {
        VStack(spacing: 20) {
            Text("New list")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 12)

            TextField("", text: $name, prompt: Text("e.g. Weekend BBQ").foregroundStyle(Theme.textSecondary))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                .padding(.horizontal, 20)

            if appState.hasConnections {
                Toggle(isOn: $isShared) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share this list").font(.system(size: 14, weight: .medium))
                        Text("Everyone you're connected to sees it live").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                    }
                }
                .tint(Theme.primary)
                .padding(.horizontal, 20)
            }

            Button {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                appState.createCart(name: trimmed, isShared: isShared)
                dismiss()
            } label: {
                Text("Create list")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Theme.background)
    }
}
