import SwiftUI

enum Theme {
    // A night-time terminal, not a startup dashboard.
    static let ink = Color(hex: 0x070B14)
    static let inkLift = Color(hex: 0x0D1524)
    static let card = Color(hex: 0x121B2B)
    static let stroke = Color.white.opacity(0.07)
    static let primary = Color(hex: 0xF2F6FC)
    static let secondary = Color(hex: 0x8D9BB0)
    static let teal = Color(hex: 0x37D6C4)
    static let amber = Color(hex: 0xFFB020)
    static let red = Color(hex: 0xFF5F5F)
    static let blue = Color(hex: 0x5B9BFF)

    static let routeGradient = LinearGradient(
        colors: [Color(hex: 0x0B1220), Color(hex: 0x0B1A26), Color(hex: 0x081019)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func statusColor(_ status: FlightStatus) -> Color {
        switch status {
        case .onTime: teal
        case .boarding: blue
        case .delayed: amber
        case .departed: secondary
        case .cancelled: red
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Airline tints arrive as hex strings from the API, so the UI does not
    /// hard-code a brand list that will go stale.
    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        self.init(hex: UInt32(cleaned, radix: 16) ?? 0x8D9BB0)
    }
}

extension View {
    func cardSurface() -> some View {
        self
            .background(Theme.card, in: .rect(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}
