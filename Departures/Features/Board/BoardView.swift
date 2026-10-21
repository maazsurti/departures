import SwiftUI

/// Regular width gets the iPad layout the airport board deserves: the board
/// stays in its own column while a flight opens beside it. Compact width
/// collapses to the same navigation stack the phone had.
struct BoardView: View {
    @Environment(BoardViewModel.self) private var model
    @Environment(Router.self) private var router

    @State private var selection: Flight.ID?
    @State private var path = NavigationPath()
    @State private var pendingNumber: String?
    @State private var width: CGFloat = 0

    /// A 744pt iPad mini portrait cannot hold a board column and a detail pane
    /// without squeezing both, so it gets the stack. Wider iPads keep the split.
    private var usesSplitView: Bool { width >= 820 }

    var body: some View {
        Group {
            if usesSplitView {
                NavigationSplitView {
                    BoardListView(selection: $selection)
                        .navigationSplitViewColumnWidth(min: 340, ideal: 400, max: 520)
                } detail: {
                    if let flight = selection.flatMap(model.flight(withID:)) {
                        FlightDetailView(flight: flight)
                    } else {
                        FlightDetailPlaceholder(
                            flights: Array(model.visibleFlights.prefix(3)),
                            onSelect: { selection = $0 }
                        )
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack(path: $path) {
                    BoardListView()
                        .navigationDestination(for: Flight.self) { flight in
                            FlightDetailView(flight: model.flight(withID: flight.id) ?? flight)
                        }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            self.width = width
        }
        .task {
            await model.load()
            openPendingFlight()
            handleDeepLink()
            #if DEBUG
            // Screenshot/QA hook: open straight to a flight without tapping.
            if let number = ProcessInfo.processInfo.environment["OPEN_FLIGHT"] {
                show(number: number)
            }
            #endif
        }
        .onChange(of: router.deepLinkedFlight) { _, _ in
            handleDeepLink()
        }
    }

    /// Deep links can arrive before the board has loaded, so remember the
    /// number and resolve it once the flights are in.
    private func show(number: String) {
        guard let flight = model.flights.first(where: { $0.number == number }) else {
            pendingNumber = number
            return
        }
        selection = flight.id
        if !usesSplitView {
            path.append(flight)
        }
    }

    private func handleDeepLink() {
        guard let number = router.deepLinkedFlight else { return }
        router.deepLinkedFlight = nil
        show(number: number)
    }

    private func openPendingFlight() {
        guard let pendingNumber else { return }
        self.pendingNumber = nil
        show(number: pendingNumber)
    }
}

#Preview {
    BoardView()
        .environment(BoardViewModel())
        .environment(SavedFlights())
        .environment(Router())
}
