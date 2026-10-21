import SwiftUI

struct TodayView: View {
    let service: DemoFlightService

    @Environment(BoardViewModel.self) private var board
    @Environment(SavedFlights.self) private var saved
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingSettings = false

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    private var savedFlights: [Flight] {
        board.flights
            .filter { saved.contains($0.number) && $0.status != .departed }
            .sorted { $0.displayTime < $1.displayTime }
    }

    private var changes: [Flight] {
        Array(board.attentionFlights.prefix(4))
    }

    private var upcoming: [Flight] {
        Array(board.upcomingDepartures.dropFirst().prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    searchLink
                    nextDeparture
                    stats
                    upcomingSection
                    savedSection
                    changesSection
                    otherBoards
                }
                .padding(.horizontal, sizeClass == .regular ? 32 : 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Theme.routeGradient.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task { await board.load() }
            .sheet(isPresented: $showingSettings) {
                SettingsView(service: service)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting.uppercased())
                    .themeFont(11, weight: .bold, design: .rounded)
                    .tracking(2.4)
                    .foregroundStyle(Theme.teal)

                Text(board.airport.city)
                    .themeFont(34, weight: .bold, design: .rounded)
                    .foregroundStyle(Theme.primary)

                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .themeFont(13, design: .rounded)
                    .foregroundStyle(Theme.secondary)
            }

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .themeFont(16, weight: .semibold)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.06), in: .circle)
                    .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("open-settings")
            .accessibilityLabel("Settings")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private var searchLink: some View {
        NavigationLink {
            FlightSearchView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .themeFont(14, weight: .semibold, design: .default)
                    .foregroundStyle(Theme.teal)

                Text("Find a flight anywhere")
                    .themeFont(14, weight: .medium, design: .rounded)
                    .foregroundStyle(Theme.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .themeFont(11, weight: .semibold, design: .default)
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .cardSurface()
        }
        .buttonStyle(.plain)
    }

    private var nextDeparture: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("NEXT DEPARTURE")
                    .themeFont(10, weight: .bold, design: .rounded)
                    .tracking(1.6)
                    .foregroundStyle(Theme.secondary)

                Spacer()

                if let flight = board.nextDeparture {
                    Text(countdown(to: flight.displayTime))
                        .themeFont(11, weight: .bold, design: .rounded)
                        .foregroundStyle(Theme.teal)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Theme.teal.opacity(0.12), in: .capsule)
                }
            }

            if let flight = board.nextDeparture {
                NavigationLink {
                    FlightDetailView(flight: board.flight(withID: flight.id) ?? flight)
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Text(flight.number)
                                .themeFont(12, weight: .semibold, design: .monospaced)
                                .foregroundStyle(Theme.secondary)
                            StatusPill(status: flight.status)
                            Spacer()
                            Text(time(flight.displayTime))
                                .themeFont(25, weight: .semibold, design: .rounded)
                                .monospacedDigit()
                                .foregroundStyle(Theme.primary)
                        }

                        HStack(spacing: 12) {
                            Text(flight.destination.code)
                                .themeFont(40, weight: .heavy, design: .rounded)
                                .foregroundStyle(Theme.primary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(flight.destination.city)
                                    .themeFont(17, weight: .semibold, design: .rounded)
                                    .foregroundStyle(Theme.primary)
                                Text("Gate \(flight.gate) · \(flight.terminal)")
                                    .themeFont(12, design: .rounded)
                                    .foregroundStyle(Theme.secondary)
                            }

                            Spacer()

                            Image(systemName: "airplane")
                                .themeFont(20, weight: .semibold, design: .default)
                                .foregroundStyle(Theme.teal)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            } else {
                Text(board.isLoading ? "Loading the board…" : "No departures left today at \(board.airport.code).")
                    .themeFont(14, design: .rounded)
                    .foregroundStyle(Theme.secondary)
                    .padding(.vertical, 6)
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statTile(value: board.boardStats(for: board.airport).departures, label: "Departures", tint: Theme.primary)
            statTile(value: board.boardStats(for: board.airport).delayed, label: "Delayed", tint: Theme.amber)
            statTile(value: board.boardStats(for: board.airport).gates, label: "Gate moves", tint: Theme.red)
        }
    }

    private func statTile(value: Int, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .themeFont(26, weight: .bold, design: .rounded)
                .monospacedDigit()
                .foregroundStyle(tint)
            Text(label)
                .themeFont(11, design: .rounded)
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardSurface()
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("UPCOMING")
                    .themeFont(10, weight: .bold)
                    .tracking(1.6)
                    .foregroundStyle(Theme.secondary)

                Spacer()

                Button("Open board") {
                    router.tab = .board
                }
                .themeFont(12, weight: .semibold)
                .foregroundStyle(Theme.teal)
            }

            ForEach(upcoming) { flight in
                NavigationLink {
                    FlightDetailView(flight: board.flight(withID: flight.id) ?? flight)
                } label: {
                    BoardRow(flight: flight)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("upcoming-\(flight.number)")
            }
        }
    }

    @ViewBuilder
    private var savedSection: some View {
        if savedFlights.isEmpty {
            Button {
                router.tab = .board
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "star")
                        .themeFont(16, weight: .semibold, design: .default)
                        .foregroundStyle(Theme.amber)
                        .frame(width: 36, height: 36)
                        .background(Theme.amber.opacity(0.12), in: .rect(cornerRadius: 11))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save a flight")
                            .themeFont(14, weight: .semibold, design: .rounded)
                            .foregroundStyle(Theme.primary)
                        Text("Long-press a board row to follow its gate.")
                            .themeFont(12, design: .rounded)
                            .foregroundStyle(Theme.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .themeFont(11, weight: .semibold, design: .default)
                        .foregroundStyle(Theme.secondary)
                }
                .padding(14)
                .cardSurface()
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("SAVED")
                        .themeFont(10, weight: .bold, design: .rounded)
                        .tracking(1.6)
                        .foregroundStyle(Theme.secondary)

                    Spacer()

                    Button("See all") {
                        router.tab = .saved
                    }
                    .themeFont(12, weight: .semibold, design: .rounded)
                    .foregroundStyle(Theme.teal)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(savedFlights.prefix(4)) { flight in
                            NavigationLink {
                                FlightDetailView(flight: board.flight(withID: flight.id) ?? flight)
                            } label: {
                                SavedFlightCard(flight: flight)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CHANGES")
                    .themeFont(10, weight: .bold, design: .rounded)
                    .tracking(1.6)
                    .foregroundStyle(Theme.secondary)

                Spacer()

                if !changes.isEmpty {
                    Button("See all") {
                        router.tab = .changes
                    }
                    .themeFont(12, weight: .semibold, design: .rounded)
                    .foregroundStyle(Theme.teal)
                }
            }

            if changes.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.teal)
                    Text("No delays, cancellations or gate moves right now.")
                        .themeFont(13, design: .rounded)
                        .foregroundStyle(Theme.secondary)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .cardSurface()
            } else {
                ForEach(changes) { flight in
                    NavigationLink {
                        FlightDetailView(flight: board.flight(withID: flight.id) ?? flight)
                    } label: {
                        ChangeRow(flight: flight)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var otherBoards: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OTHER BOARDS")
                .themeFont(10, weight: .bold)
                .tracking(1.6)
                .foregroundStyle(Theme.secondary)

            ForEach(board.airports.filter { $0.code != board.airport.code }) { airport in
                Button {
                    board.airport = airport
                    router.tab = .board
                } label: {
                    HStack(spacing: 12) {
                        Text(airport.code)
                            .themeFont(18, weight: .heavy, design: .monospaced)
                            .foregroundStyle(Theme.primary)
                            .frame(width: 56, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(airport.city)
                                .themeFont(15, weight: .semibold)
                                .foregroundStyle(Theme.primary)
                            Text("\(board.departureCount(for: airport)) departures · \(board.boardStats(for: airport).delayed) delayed")
                                .themeFont(11)
                                .foregroundStyle(Theme.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .themeFont(11, weight: .semibold)
                            .foregroundStyle(Theme.secondary)
                    }
                    .padding(14)
                    .cardSurface()
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("other-board-\(airport.code)")
            }
        }
    }

    private func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func countdown(to date: Date) -> String {
        let minutes = Int((date.timeIntervalSinceNow / 60).rounded(.down))
        return minutes <= 0 ? "Due now" : "in \(minutes) min"
    }
}

#Preview {
    TodayView(service: DemoFlightService())
        .environment(BoardViewModel())
        .environment(SavedFlights())
        .environment(Router())
}
