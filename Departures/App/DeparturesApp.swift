import SwiftUI

@main
struct DeparturesApp: App {
    private let service = DemoFlightService()

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetDemoState"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        #endif
    }
    var body: some Scene {
        WindowGroup {
            RootView(service: service)
        }
    }
}
