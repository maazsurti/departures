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

    private let repository: FlightRepository

    init(repository: FlightRepository = DemoFlightService()) {
        self.repository = repository
    }

    /// Filtering lives here rather than in the view so it can be tested without
    /// booting SwiftUI. Search is case- and diacritic-insensitive because people
    /// type "queenstown" at a gate, not "Queenstown".
    var visibleFlights: [Flight] {
        let filtered = flights.filter { flight in
            switch filter {
            case .departures:
                flight.status != .departed
            case .delayed:
                flight.status.isUrgent
            }
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return filtered }

        return filtered.filter { flight in
            [flight.number, flight.destination.city, flight.destination.code, flight.gate]
                .contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
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
