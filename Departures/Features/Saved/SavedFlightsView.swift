import SwiftUI

struct SavedFlightsView: View {
    @Environment(BoardViewModel.self) private var board
    @Environment(SavedFlights.self) private var saved

    private var flights: [Flight] {
        board.flights
            .filter { saved.contains($0.number) && $0.status != .departed }
            .sorted { $0.displayTime < $1.displayTime }
    }

    var body: some View {
        NavigationStack {
            Group {
                if flights.isEmpty {
                    ContentUnavailableView {
                        Label("No saved flights", systemImage: "star")
                    } description: {
                        Text("Long-press a flight on the board, or star it on its detail screen.")
                    }
                } else {
                    List {
                        ForEach(flights) { flight in
                            NavigationLink(value: flight) {
                                BoardRow(flight: flight)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .accessibilityIdentifier("saved-row-\(flight.number)")
                            .swipeActions {
                                Button("Remove", systemImage: "star.slash", role: .destructive) {
                                    saved.toggle(flight.number)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.routeGradient.ignoresSafeArea())
            .navigationTitle("Saved flights")
            .navigationDestination(for: Flight.self) { flight in
                FlightDetailView(flight: board.flight(withID: flight.id) ?? flight)
            }
        }
        .preferredColorScheme(.dark)
        .task { await board.load() }
    }
}

#Preview {
    SavedFlightsView()
        .environment(BoardViewModel())
        .environment(SavedFlights())
}
