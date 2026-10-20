import Foundation
import Testing
@testable import Departures

private enum StubError: Error { case offline }

private struct StubRepository: FlightRepository {
    let flights: [Flight]
    var fails = false
    var cached: CachedBoard?

    func departures() async throws -> [Flight] {
        if fails { throw StubError.offline }
        return flights
    }

    func cachedSnapshot() async -> CachedBoard? {
        cached
    }
}

private func makeFlight(
    number: String,
    destination: Airport = .syd,
    gate: String = "12",
    previousGate: String? = nil,
    status: FlightStatus = .onTime,
    delayMinutes: Int = 0
) -> Flight {
    let scheduled = Date(timeIntervalSince1970: 1_800_000_000)
    return Flight(
        id: UUID(),
        number: number,
        airline: Airline(code: "NZ", name: "Air New Zealand", tint: "00A0A8"),
        origin: .akl,
        destination: destination,
        scheduled: scheduled,
        estimated: delayMinutes > 0 ? scheduled.addingTimeInterval(TimeInterval(delayMinutes * 60)) : nil,
        gate: gate,
        previousGate: previousGate,
        terminal: "Domestic",
        aircraft: "A320",
        status: status
    )
}

@MainActor
struct BoardViewModelTests {

    @Test func loadPublishesFlightsAndTimestamp() async {
        let flights = [makeFlight(number: "NZ 1"), makeFlight(number: "NZ 2")]
        let model = BoardViewModel(repository: StubRepository(flights: flights))

        #expect(model.flights.isEmpty)
        await model.load()

        #expect(model.flights.count == 2)
        #expect(model.lastUpdated != nil)
        #expect(model.errorMessage == nil)
        #expect(model.isShowingCachedData == false)
    }

    @Test func departedFlightsAreHiddenFromTheDefaultBoard() async {
        let model = BoardViewModel(repository: StubRepository(flights: [
            makeFlight(number: "NZ 1", status: .boarding),
            makeFlight(number: "NZ 2", status: .departed)
        ]))
        await model.load()

        #expect(model.visibleFlights.map(\.number) == ["NZ 1"])
    }

    @Test func delayedFilterKeepsOnlyUrgentFlights() async {
        let model = BoardViewModel(repository: StubRepository(flights: [
            makeFlight(number: "NZ 1", status: .onTime),
            makeFlight(number: "NZ 2", status: .delayed, delayMinutes: 30),
            makeFlight(number: "NZ 3", status: .cancelled)
        ]))
        await model.load()
        model.filter = .delayed

        #expect(Set(model.visibleFlights.map(\.number)) == ["NZ 2", "NZ 3"])
    }

    @Test func searchMatchesCityGateAndFlightNumberCaseInsensitively() async {
        let model = BoardViewModel(repository: StubRepository(flights: [
            makeFlight(number: "NZ 103", destination: .syd, gate: "17"),
            makeFlight(number: "NZ 612", destination: .zqn, gate: "34")
        ]))
        await model.load()

        model.query = "queenstown"
        #expect(model.visibleFlights.map(\.number) == ["NZ 612"])

        model.query = "17"
        #expect(model.visibleFlights.map(\.number) == ["NZ 103"])

        model.query = "nz 612"
        #expect(model.visibleFlights.map(\.number) == ["NZ 612"])
    }

    @Test func whitespaceOnlySearchDoesNotFilterAnything() async {
        let model = BoardViewModel(repository: StubRepository(flights: [makeFlight(number: "NZ 1")]))
        await model.load()
        model.query = "   "

        #expect(model.visibleFlights.count == 1)
    }

    @Test func failureSurfacesMessageAndKeepsBoardUsable() async {
        let model = BoardViewModel(repository: StubRepository(flights: [], fails: true))
        await model.load()

        #expect(model.errorMessage != nil)
        #expect(model.flights.isEmpty)
    }

    @Test func failureFallsBackToCachedSnapshotAndSaysSo() async {
        let savedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let cached = CachedBoard(flights: [makeFlight(number: "NZ 1")], savedAt: savedAt)
        let model = BoardViewModel(
            repository: StubRepository(flights: [], fails: true, cached: cached)
        )

        await model.load()

        #expect(model.flights.count == 1)
        #expect(model.isShowingCachedData)
        #expect(model.lastUpdated == savedAt)
        #expect(model.errorMessage != nil)
    }

    @Test func gateChangeIsVisibleOnTheModel() {
        let changed = makeFlight(number: "NZ 1", gate: "41", previousGate: "34")
        let unchanged = makeFlight(number: "NZ 2")

        #expect(changed.gateChanged)
        #expect(changed.previousGate == "34")
        #expect(unchanged.gateChanged == false)
    }
}

struct FlightTests {

    @Test func delayMinutesNeverGoesNegative() {
        let flight = makeFlight(number: "NZ 1", delayMinutes: 0)
        #expect(flight.delayMinutes == 0)
    }

    @Test func displayTimePrefersEstimate() {
        let onTime = makeFlight(number: "NZ 1")
        let delayed = makeFlight(number: "NZ 2", delayMinutes: 25)

        #expect(onTime.displayTime == onTime.scheduled)
        #expect(delayed.delayMinutes == 25)
        #expect(delayed.displayTime > delayed.scheduled)
    }

    @Test func progressOnlyAdvancesOnceDeparted() {
        #expect(makeFlight(number: "NZ 1", status: .onTime).progress == 0)
        #expect(makeFlight(number: "NZ 2", status: .boarding).progress > 0)
        #expect(makeFlight(number: "NZ 3", status: .cancelled).progress == 0)
    }
}
