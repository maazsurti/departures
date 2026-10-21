import Foundation

// MARK: - Domain

struct Airport: Codable, Hashable, Identifiable, Sendable {
    let code: String
    let city: String
    let name: String

    var id: String { code }

    static let akl = Airport(code: "AKL", city: "Auckland", name: "Auckland Airport")
    static let syd = Airport(code: "SYD", city: "Sydney", name: "Kingsford Smith")
    static let zqn = Airport(code: "ZQN", city: "Queenstown", name: "Queenstown Airport")
    static let wlg = Airport(code: "WLG", city: "Wellington", name: "Wellington Airport")
    static let chc = Airport(code: "CHC", city: "Christchurch", name: "Christchurch Airport")
    static let mel = Airport(code: "MEL", city: "Melbourne", name: "Tullamarine")
    static let nrt = Airport(code: "NRT", city: "Tokyo", name: "Narita")
    static let sin = Airport(code: "SIN", city: "Singapore", name: "Changi")

    static let all: [Airport] = [.akl, .wlg, .chc, .zqn, .syd, .mel, .nrt, .sin]
}

struct Airline: Codable, Hashable, Sendable {
    let code: String
    let name: String
    /// Hex string, kept in the domain so the UI layer stays dumb.
    let tint: String
}

enum FlightStatus: String, Codable, CaseIterable, Sendable {
    case onTime
    case boarding
    case delayed
    case departed
    case cancelled

    var label: String {
        switch self {
        case .onTime: "On time"
        case .boarding: "Boarding"
        case .delayed: "Delayed"
        case .departed: "Departed"
        case .cancelled: "Cancelled"
        }
    }

    var isUrgent: Bool {
        switch self {
        case .delayed, .cancelled: true
        default: false
        }
    }
}

struct Flight: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let number: String
    let airline: Airline
    let origin: Airport
    let destination: Airport
    let scheduled: Date
    let estimated: Date?
    let gate: String
    let previousGate: String?
    let terminal: String
    let aircraft: String
    let status: FlightStatus

    var gateChanged: Bool { previousGate != nil }

    var displayTime: Date { estimated ?? scheduled }

    var delayMinutes: Int {
        guard let estimated else { return 0 }
        return max(0, Int(estimated.timeIntervalSince(scheduled) / 60))
    }

    /// 0...1 along the route. Derived, never stored, so a stale snapshot cannot lie
    /// about where an aircraft is.
    var progress: Double {
        switch status {
        case .departed:
            let elapsed = Date.now.timeIntervalSince(scheduled)
            return min(1, max(0.05, elapsed / (3 * 3600)))
        case .boarding:
            return 0.02
        default:
            return 0
        }
    }
}
