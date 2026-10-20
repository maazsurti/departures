import SwiftUI

struct StatusPill: View {
    let status: FlightStatus

    private var color: Color { Theme.statusColor(status) }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(status.label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: .capsule)
        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
        .accessibilityLabel("Status: \(status.label)")
    }
}

struct AirlineMark: View {
    let airline: Airline

    var body: some View {
        Text(airline.code)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(hexString: airline.tint))
            .frame(width: 30, height: 30)
            .background(Color(hexString: airline.tint).opacity(0.14), in: .rect(cornerRadius: 9))
            .accessibilityHidden(true)
    }
}
