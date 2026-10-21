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
    private var isOffline = false

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

        guard !isOffline else { throw URLError(.notConnectedToInternet) }

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

    /// Demo control for the offline path, so the cached-state UI can be shown
    /// without turning Wi-Fi off.
    func setOffline(_ offline: Bool) {
        isOffline = offline
    }

    func isCurrentlyOffline() -> Bool {
        isOffline
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
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000007")!,
                number: "NZ 512",
                airline: airline,
                origin: .wlg,
                destination: .chc,
                scheduled: at(45),
                estimated: nil,
                gate: "8",
                previousGate: "6",
                terminal: "Domestic",
                aircraft: "ATR 72-600",
                status: .boarding
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000008")!,
                number: "NZ 532",
                airline: airline,
                origin: .wlg,
                destination: .akl,
                scheduled: at(80),
                estimated: nil,
                gate: "4",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "Airbus A320neo",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000009")!,
                number: "QF 162",
                airline: partner,
                origin: .wlg,
                destination: .syd,
                scheduled: at(150),
                estimated: at(175),
                gate: "3",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 737-800",
                status: .delayed
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000010")!,
                number: "NZ 305",
                airline: airline,
                origin: .chc,
                destination: .wlg,
                scheduled: at(35),
                estimated: nil,
                gate: "14",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "Airbus A320neo",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000011")!,
                number: "NZ 245",
                airline: airline,
                origin: .chc,
                destination: .syd,
                scheduled: at(110),
                estimated: at(140),
                gate: "27",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 787-9",
                status: .delayed
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000012")!,
                number: "NZ 617",
                airline: airline,
                origin: .chc,
                destination: .zqn,
                scheduled: at(205),
                estimated: nil,
                gate: "11",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "ATR 72-600",
                status: .cancelled
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000013")!,
                number: "NZ 23",
                airline: airline,
                origin: .akl,
                destination: .wlg,
                scheduled: at(35),
                estimated: nil,
                gate: "20",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "ATR 72-600",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000014")!,
                number: "NZ 501",
                airline: airline,
                origin: .akl,
                destination: .chc,
                scheduled: at(75),
                estimated: nil,
                gate: "33",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "Airbus A321neo",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000015")!,
                number: "NZ 289",
                airline: airline,
                origin: .akl,
                destination: .wlg,
                scheduled: at(115),
                estimated: at(130),
                gate: "28",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "Airbus A320neo",
                status: .delayed
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000016")!,
                number: "NZ 7",
                airline: airline,
                origin: .akl,
                destination: .sin,
                scheduled: at(240),
                estimated: nil,
                gate: "5",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 787-9",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000017")!,
                number: "NZ 80",
                airline: airline,
                origin: .akl,
                destination: .nrt,
                scheduled: at(300),
                estimated: nil,
                gate: "8",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 787-9",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000018")!,
                number: "NZ 543",
                airline: airline,
                origin: .wlg,
                destination: .chc,
                scheduled: at(60),
                estimated: nil,
                gate: "5",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "ATR 72-600",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000019")!,
                number: "NZ 582",
                airline: airline,
                origin: .wlg,
                destination: .akl,
                scheduled: at(95),
                estimated: at(105),
                gate: "7",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "Airbus A320neo",
                status: .delayed
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000020")!,
                number: "QF 166",
                airline: partner,
                origin: .wlg,
                destination: .mel,
                scheduled: at(180),
                estimated: nil,
                gate: "2",
                previousGate: nil,
                terminal: "International",
                aircraft: "Boeing 737-800",
                status: .cancelled
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000021")!,
                number: "NZ 315",
                airline: airline,
                origin: .chc,
                destination: .akl,
                scheduled: at(50),
                estimated: nil,
                gate: "16",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "Airbus A320neo",
                status: .onTime
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000022")!,
                number: "NZ 259",
                airline: airline,
                origin: .chc,
                destination: .mel,
                scheduled: at(130),
                estimated: at(150),
                gate: "24",
                previousGate: "21",
                terminal: "International",
                aircraft: "Airbus A321neo",
                status: .delayed
            ),
            Flight(
                id: UUID(uuidString: "6F1B6B1E-0000-0000-0000-000000000023")!,
                number: "NZ 633",
                airline: airline,
                origin: .chc,
                destination: .zqn,
                scheduled: at(190),
                estimated: nil,
                gate: "9",
                previousGate: nil,
                terminal: "Domestic",
                aircraft: "ATR 72-600",
                status: .onTime
            )
        ]
    }
}
