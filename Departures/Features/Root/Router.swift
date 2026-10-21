import Foundation
import Observation

/// Which tab is showing. Owned above the TabView so dashboard actions can hand
/// the traveller to another section instead of duplicating it.
@MainActor
@Observable
final class Router {
    enum Tab: String, Hashable {
        case today
        case board
        case saved
        case changes
    }

    var tab: Tab = .today
}
