import SwiftUI

struct ChangesView: View {
    @Environment(BoardViewModel.self) private var board

    private struct Section: Identifiable {
        let airport: Airport
        let flights: [Flight]

        var id: String { airport.code }
    }

    private var sections: [Section] {
        board.airports.compactMap { airport in
            let flights = board.attentionFlights.filter { $0.origin == airport }
            return flights.isEmpty ? nil : Section(airport: airport, flights: flights)
        }
    }

    private var cancelledCount: Int {
        board.attentionFlights.filter { $0.status == .cancelled }.count
    }

    private var delayedCount: Int {
        board.attentionFlights.filter { $0.status == .delayed }.count
    }

    private var gateCount: Int {
        board.attentionFlights.filter(\.gateChanged).count
    }

    var body: some View {
        NavigationStack {
            Group {
                if board.isLoading {
                    ProgressView()
                        .tint(Theme.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if board.attentionFlights.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing needs attention", systemImage: "checkmark.circle")
                    } description: {
                        Text("Delays, cancellations and gate moves appear here.")
                    }
                } else {
                    List {
                        summary
                            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 8, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        ForEach(sections) { section in
                            SwiftUI.Section {
                                ForEach(section.flights) { flight in
                                    NavigationLink {
                                        FlightDetailView(flight: board.flight(withID: flight.id) ?? flight)
                                    } label: {
                                        ChangeRow(flight: flight)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .accessibilityIdentifier("change-row-\(flight.number)")
                                }
                            } header: {
                                Text("\(section.airport.city) · \(section.airport.code)")
                                    .themeFont(11, weight: .bold)
                                    .tracking(1.2)
                                    .foregroundStyle(Theme.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.routeGradient.ignoresSafeArea())
            .navigationTitle("Changes")
            .tint(Theme.teal)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FlightSearchView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Find a flight")
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await board.load() }
    }

    private var summary: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(board.attentionCount) flights need attention")
                    .themeFont(20, weight: .bold)
                    .foregroundStyle(Theme.primary)

                Text("\(cancelledCount) cancelled · \(delayedCount) delayed · \(gateCount) gate moves")
                    .themeFont(12)
                    .foregroundStyle(Theme.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "exclamationmark.triangle.fill")
                .themeFont(18, weight: .semibold)
                .foregroundStyle(Theme.amber)
        }
        .padding(16)
        .cardSurface()
        .accessibilityIdentifier("changes-summary")
    }
}

#Preview {
    ChangesView()
        .environment(BoardViewModel())
}
