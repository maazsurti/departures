import SwiftUI

struct BoardRow: View {
    let flight: Flight

    private var timeText: String {
        flight.displayTime.formatted(date: .omitted, time: .shortened)
    }

    private var originalTimeText: String {
        flight.scheduled.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 14) {
            AirlineMark(airline: flight.airline)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(flight.number)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.secondary)

                    if flight.delayMinutes > 0 {
                        Text("+\(flight.delayMinutes)m")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.amber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.amber.opacity(0.12), in: .capsule)
                    }
                }

                Text(flight.destination.city)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.primary)

                HStack(spacing: 6) {
                    Text("Gate \(flight.gate) · \(flight.terminal)")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.secondary)

                    if let previous = flight.previousGate {
                        Text("was \(previous)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.amber)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text(timeText)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.primary)
                    .contentTransition(.numericText())

                StatusPill(status: flight.status)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(flight.number) to \(flight.destination.city), \(flight.status.label), "
            + "departs \(timeText), gate \(flight.gate)"
        )
    }
}

#Preview {
    ZStack {
        Theme.ink.ignoresSafeArea()
        BoardRow(flight: PreviewData.flights[1])
            .padding()
    }
}

enum PreviewData {
    static let flights: [Flight] = {
        let airline = Airline(code: "NZ", name: "Air New Zealand", tint: "00A0A8")
        return [
            Flight(
                id: UUID(),
                number: "NZ 103",
                airline: airline,
                origin: .akl,
                destination: .syd,
                scheduled: .now.addingTimeInterval(3000),
                estimated: nil,
                gate: "12",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 787-9",
                status: .boarding
            ),
            Flight(
                id: UUID(),
                number: "NZ 612",
                airline: airline,
                origin: .akl,
                destination: .zqn,
                scheduled: .now.addingTimeInterval(5400),
                estimated: .now.addingTimeInterval(7200),
                gate: "41",
                previousGate: "34",
                terminal: "Domestic",
                aircraft: "Airbus A320neo",
                status: .delayed
            )
        ]
    }()
}
