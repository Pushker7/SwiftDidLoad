import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s.removeAll { $0 == "#" }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    static let background = Color(hex: "F4F6FB")      // Blinkit light gray-blue background
    static let card = Color(hex: "FFFFFF")            // White card content background
    static let border = Color(hex: "E5E7EB")          // Very light gray borders
    static let textPrimary = Color(hex: "1F1F1F")     // Dark charcoal for main text
    static let textSecondary = Color(hex: "6B7280")   // Medium gray for descriptions and units
    static let primary = Color(hex: "0C831F")         // Official Blinkit Green
    
    static let offerText = Color(hex: "C2410C")        // Deep orange for discount details
    static let offerBackground = Color(hex: "FEF3C7")  // Light warm gold for savings background
}

let memberColors = ["#16A34A", "#2563EB", "#7C3AED", "#D97706", "#DC2626", "#0891B2"]

struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

struct LiquidGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.25))
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .clear, .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 16) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
    
    func liquidGlassBackground(cornerRadius: CGFloat = 16) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius))
    }
}

struct QtyStepper: View {
    let qty: Int
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button {
                onChange(qty - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Text("\(qty)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(minWidth: 12)

            Button {
                onChange(qty + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Theme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

func avatar(name: String, hex: String, size: CGFloat) -> some View {
    Circle()
        .fill(Color(hex: hex))
        .frame(width: size, height: size)
        .overlay(
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.45, weight: .black))
                .foregroundStyle(.white)
        )
}
