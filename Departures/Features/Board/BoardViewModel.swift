import Foundation
import Observation

@MainActor
@Observable
final class BoardViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case departures = "Departures"
        case delayed = "Delayed"

        var id: String { rawValue }
    }

    private(set) var flights: [Flight] = []
    private(set) var isLoading = false
    private(set) var lastUpdated: Date?
    private(set) var isShowingCachedData = false
    var errorMessage: String?
    var filter: Filter = .departures
    var query = ""
    var airport: Airport {
        didSet { defaults.set(airport.code, forKey: Self.airportKey) }
    }

    private static let airportKey = "selectedAirport"
    private let repository: FlightRepository
    private let defaults: UserDefaults

    init(
        repository: FlightRepository = DemoFlightService(),
        airport: Airport = .akl,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.defaults = defaults
        self.airport = Airport.all.first { $0.code == defaults.string(forKey: Self.airportKey) } ?? airport
    }

    /// Flights that changed after they were first shown: delays, cancellations
    /// and moved gates. Not tied to the selected airport, because a gate change
    /// still matters after the traveller switches boards.
    var attentionFlights: [Flight] {
        flights
            .filter { $0.status != .departed && ($0.status.isUrgent || $0.gateChanged) }
            .sorted { lhs, rhs in
                if lhs.status != rhs.status {
                    return severity(lhs.status) < severity(rhs.status)
                }
                return lhs.displayTime < rhs.displayTime
            }
    }

    var attentionCount: Int { attentionFlights.count }

    /// The soonest flight still on the ground at the selected airport.
    var nextDeparture: Flight? {
        upcomingDepartures.first
    }

    var upcomingDepartures: [Flight] {
        flights
            .filter { $0.origin == airport && $0.status != .departed }
            .sorted { $0.displayTime < $1.displayTime }
    }

    func boardStats(for airport: Airport) -> (departures: Int, delayed: Int, gates: Int) {
        let scoped = flights.filter { $0.origin == airport && $0.status != .departed }
        return (
            departures: scoped.count,
            delayed: scoped.filter(\.status.isUrgent).count,
            gates: scoped.filter(\.gateChanged).count
        )
    }

    private func severity(_ status: FlightStatus) -> Int {
        switch status {
        case .cancelled: 0
        case .delayed: 1
        default: 2
        }
    }

    /// Airports the demo board actually has departures for. Derived from the
    /// data so the picker cannot offer an empty board.
    var airports: [Airport] {
        let codes = Set(flights.map(\.origin))
        return codes.sorted { $0.code < $1.code }
    }

    func departureCount(for airport: Airport) -> Int {
        flights.filter { $0.origin == airport && $0.status != .departed }.count
    }

    func flight(withID id: Flight.ID) -> Flight? {
        flights.first { $0.id == id }
    }

    /// Filtering lives here rather than in the view so it can be tested without
    /// booting SwiftUI. Search is case- and diacritic-insensitive because people
    /// type "queenstown" at a gate, not "Queenstown".
    var visibleFlights: [Flight] {
        let filtered = flights.filter { flight in
            guard flight.origin == airport else { return false }
            switch filter {
            case .departures:
                return flight.status != .departed
            case .delayed:
                return flight.status.isUrgent
            }
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return filtered.sorted { $0.displayTime < $1.displayTime }
        }

        return filtered
            .filter { flight in
                [flight.number, flight.destination.city, flight.destination.code, flight.gate]
                    .contains { $0.localizedCaseInsensitiveContains(trimmed) }
            }
            .sorted { $0.displayTime < $1.displayTime }
    }

    func load() async {
        guard flights.isEmpty else { return }
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    private func fetch() async {
        isLoading = flights.isEmpty
        defer { isLoading = false }

        do {
            flights = try await repository.departures()
            lastUpdated = .now
            isShowingCachedData = false
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if let cached = await repository.cachedSnapshot() {
                flights = cached.flights
                lastUpdated = cached.savedAt
                isShowingCachedData = true
            }
            errorMessage = "Could not reach the board. Showing the last saved update."
        }
    }
}
