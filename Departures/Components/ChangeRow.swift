import SwiftUI

/// One row in the changes feed: what changed, for which flight, and when it now
/// leaves. Shared by the Changes tab and the Today preview.
struct ChangeRow: View {
    let flight: Flight

    private var summary: (title: String, detail: String, icon: String, tint: Color) {
        if flight.status == .cancelled {
            return (
                "Cancelled",
                "\(flight.number) to \(flight.destination.city) will not depart.",
                "xmark.octagon.fill",
                Theme.red
            )
        }
        if let previous = flight.previousGate {
            return (
                "Gate changed",
                "Now gate \(flight.gate), was \(previous). \(flight.number) to \(flight.destination.city).",
                "arrow.triangle.swap",
                Theme.amber
            )
        }
        return (
            "Delayed by \(flight.delayMinutes) min",
            "Now \(time(flight.displayTime)), was \(time(flight.scheduled)).",
            "clock.badge.exclamationmark.fill",
            Theme.amber
        )
    }

    var body: some View {
        let summary = summary

        HStack(spacing: 12) {
            Image(systemName: summary.icon)
                .themeFont(15, weight: .semibold, design: .default)
                .foregroundStyle(summary.tint)
                .frame(width: 36, height: 36)
                .background(summary.tint.opacity(0.14), in: .rect(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(summary.title)
                        .themeFont(13, weight: .bold, design: .rounded)
                        .foregroundStyle(Theme.primary)
                    Text(flight.number)
                        .themeFont(11, weight: .semibold, design: .monospaced)
                        .foregroundStyle(Theme.secondary)
                }

                Text(summary.detail)
                    .themeFont(12, design: .rounded)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(time(flight.displayTime))
                    .themeFont(15, weight: .semibold, design: .rounded)
                    .monospacedDigit()
                    .foregroundStyle(Theme.primary)

                Text(flight.status.label.uppercased())
                    .themeFont(9, weight: .bold, design: .rounded)
                    .tracking(0.6)
                    .foregroundStyle(Theme.statusColor(flight.status))
            }
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(summary.title). \(summary.detail)")
    }

    private func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    ZStack {
        Theme.ink.ignoresSafeArea()
        VStack(spacing: 10) {
            ChangeRow(flight: PreviewData.flights[1])
            ChangeRow(flight: PreviewData.flights[0])
        }
        .padding()
    }
}
