import SwiftUI

/// Compact saved-flight card for the horizontal strip on Today. A full
/// `BoardRow` is too wide to stack four of them side by side.
struct SavedFlightCard: View {
    let flight: Flight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(flight.number)
                    .themeFont(11, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(flight.status.label.uppercased())
                    .themeFont(9, weight: .bold)
                    .tracking(0.6)
                    .foregroundStyle(Theme.statusColor(flight.status))
                    .lineLimit(1)
            }

            Text(flight.destination.city)
                .themeFont(19, weight: .semibold)
                .foregroundStyle(Theme.primary)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline) {
                Text(flight.displayTime.formatted(date: .omitted, time: .shortened))
                    .themeFont(20, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Theme.primary)

                Spacer()

                Text("Gate \(flight.gate)")
                    .themeFont(12)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(width: 250, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(flight.number) to \(flight.destination.city), \(flight.status.label), "
            + "departs \(flight.displayTime.formatted(date: .omitted, time: .shortened)), gate \(flight.gate)"
        )
    }
}

#Preview {
    ZStack {
        Theme.ink.ignoresSafeArea()
        SavedFlightCard(flight: PreviewData.flights[1])
    }
}
