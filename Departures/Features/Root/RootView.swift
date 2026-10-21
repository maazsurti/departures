import SwiftUI

/// One service instance for the whole app so the demo controls in Settings
/// change the board the traveller is actually looking at.
struct RootView: View {
    private let service: DemoFlightService
    @State private var board: BoardViewModel
    @State private var saved = SavedFlights()
    @State private var router = Router()

    init(service: DemoFlightService) {
        self.service = service
        _board = State(initialValue: BoardViewModel(repository: service))
    }

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.tab) {
            TodayView(service: service)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(Router.Tab.today)

            BoardView()
                .tabItem { Label("Board", systemImage: "airplane") }
                .tag(Router.Tab.board)

            SavedFlightsView()
                .tabItem { Label("Saved", systemImage: "star") }
                .tag(Router.Tab.saved)

            ChangesView()
                .tabItem { Label("Changes", systemImage: "arrow.triangle.swap") }
                .badge(board.attentionCount)
                .tag(Router.Tab.changes)
        }
        .tabViewStyle(.sidebarAdaptable)
        .environment(board)
        .environment(saved)
        .environment(router)
        .preferredColorScheme(.dark)
        .task {
            #if DEBUG
            if let raw = ProcessInfo.processInfo.environment["OPEN_TAB"],
               let tab = Router.Tab(rawValue: raw) {
                router.tab = tab
            }
            #endif
        }
    }
}
