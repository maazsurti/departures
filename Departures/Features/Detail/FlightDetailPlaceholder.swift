import SwiftUI

/// Shown in the detail column of the iPad split view before anything is
/// selected. The quick picks make the pane useful instead of blank.
struct FlightDetailPlaceholder: View {
    let flights: [Flight]
    let onSelect: (Flight.ID) -> Void

    var body: some View {
        ZStack {
            Theme.routeGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(Theme.teal)

                Text("Select a flight")
                    .themeFont(20, weight: .semibold)
                    .foregroundStyle(Theme.primary)

                Text("Gate, route progress and the timeline show here.")
                    .themeFont(13)
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)

                if !flights.isEmpty {
                    VStack(spacing: 8) {
                        Text("NEXT OFF THE BOARD")
                            .themeFont(9, weight: .bold)
                            .tracking(1.4)
                            .foregroundStyle(Theme.secondary)
                            .padding(.top, 10)

                        ForEach(flights) { flight in
                            Button {
                                onSelect(flight.id)
                            } label: {
                                HStack(spacing: 10) {
                                    Text(flight.number)
                                        .themeFont(12, weight: .semibold, design: .monospaced)
                                        .foregroundStyle(Theme.secondary)

                                    Text(flight.destination.city)
                                        .themeFont(14, weight: .semibold)
                                        .foregroundStyle(Theme.primary)

                                    Spacer()

                                    Text(flight.displayTime.formatted(date: .omitted, time: .shortened))
                                        .themeFont(13, weight: .semibold)
                                        .monospacedDigit()
                                        .foregroundStyle(Theme.primary)

                                    Image(systemName: "chevron.right")
                                        .themeFont(10, weight: .semibold)
                                        .foregroundStyle(Theme.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 12))
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("quick-pick-\(flight.number)")
                        }
                    }
                    .frame(maxWidth: 360)
                    .padding(.top, 8)
                }
            }
            .padding(32)
        }
        .navigationTitle("Flight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        FlightDetailPlaceholder(flights: PreviewData.flights, onSelect: { _ in })
    }
}
