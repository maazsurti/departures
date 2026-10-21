import Foundation
import Observation

/// Flight numbers the traveller is watching. Stored by number rather than the
/// fixture UUID so a saved flight survives the demo snapshot being replaced.
@MainActor
@Observable
final class SavedFlights {
    private static let key = "savedFlights"

    private let defaults: UserDefaults
    private(set) var numbers: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        numbers = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func contains(_ number: String) -> Bool {
        numbers.contains(number)
    }

    func toggle(_ number: String) {
        if numbers.contains(number) {
            numbers.remove(number)
        } else {
            numbers.insert(number)
        }
        defaults.set(numbers.sorted(), forKey: Self.key)
    }

    func removeAll() {
        numbers.removeAll()
        defaults.removeObject(forKey: Self.key)
    }
}
