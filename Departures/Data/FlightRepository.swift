import Foundation

/// The only thing the UI layer is allowed to know about the network.
protocol FlightRepository: Sendable {
    func departures() async throws -> [Flight]
    func cachedSnapshot() async -> CachedBoard?
}

struct CachedBoard: Sendable {
    let flights: [Flight]
    let savedAt: Date
}

/// Demo implementation: deterministic data, an artificial network delay, and a
/// disk snapshot so the app still has something true to show when the network
/// does not answer.
///
/// The snapshot is deliberately not used to fake freshness. The UI shows the
/// age of the data instead of pretending it is live.
actor DemoFlightService: FlightRepository {
    struct Snapshot: Codable, Sendable {
        let savedAt: Date
        let flights: [Flight]
    }

    private let latency: Duration
    private let store: URL?
    private var gateChanged = false

    init(latency: Duration = .milliseconds(450), store: URL? = DemoFlightService.defaultStore) {
        self.latency = latency
        self.store = store
    }

    static var defaultStore: URL? {
        try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "departures-snapshot.json")
    }

    func departures() async throws -> [Flight] {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SIMULATE_OFFLINE"] == "1" {
            throw URLError(.notConnectedToInternet)
        }
        #endif

        try await Task.sleep(for: latency)

        let flights = makeFlights(gateChanged: gateChanged)
        write(Snapshot(savedAt: .now, flights: flights))
        return flights
    }

    /// Simulates the one thing every traveller actually fears: the gate moving
    /// while you are already walking to the old one.
    func simulateGateChange() -> Bool {
        gateChanged.toggle()
        return gateChanged
    }

    private func loadSnapshot() -> Snapshot? {
        guard let store, let data = try? Data(contentsOf: store) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }

    func cachedSnapshot() async -> CachedBoard? {
        guard let snapshot = loadSnapshot() else { return nil }
        return CachedBoard(flights: snapshot.flights, savedAt: snapshot.savedAt)
    }

    private func write(_ snapshot: Snapshot) {
        guard let store else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: store, options: .atomic)
    }

    // MARK: - Fixtures

    private func makeFlights(gateChanged: Bool) -> [Flight] {
        let now = Date.now
        let airline = Airline(code: "NZ", name: "Air New Zealand", tint: "00A0A8")
        let partner = Airline(code: "QF", name: "Qantas", tint: "E40000")

        func at(_ minutes: Int) -> Date {
            now.addingTimeInterval(TimeInterval(minutes * 60))
        }

        return [
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000001")!,
                number: "NZ 103",
                airline: airline,
                origin: .akl,
                destination: .syd,
                scheduled: at(55),
                estimated: nil,
                gate: gateChanged ? "17" : "12",
                previousGate: gateChanged ? "12" : nil,
                terminal: "International",
                aircraft: "Boeing 787-9",
                status: .boarding
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000002")!,
                number: "NZ 612",
                airline: airline,
                origin: .akl,
                destination: .zqn,
                scheduled: at(95),
                estimated: at(125),
                gate: "41",
                previousGate: "34",
                terminal: "Domestic",
                aircraft: "Airbus A320neo",
                status: .delayed
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000003")!,
                number: "NZ 441",
                airline: airline,
                origin: .akl,
                destination: .wlg,
                scheduled: at(130),
                estimated: nil,
                gate: "22",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "ATR 72-600",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000004")!,
                number: "NZ 209",
                airline: airline,
                origin: .akl,
                destination: .chc,
                scheduled: at(160),
                estimated: nil,
                gate: "39",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "Airbus A321neo",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000005")!,
                number: "QF 152",
                airline: partner,
                origin: .akl,
                destination: .mel,
                scheduled: at(190),
                estimated: at(215),
                gate: "6",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 737-800",
                status: .delayed
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000006")!,
                number: "NZ 99",
                airline: airline,
                origin: .akl,
                destination: .nrt,
                scheduled: at(-40),
                estimated: nil,
                gate: "9",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 787-9",
                status: .departed
            )
        ]
    }
}
