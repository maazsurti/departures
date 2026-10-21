import SwiftUI

/// Looks across every airport in the demo, not just the selected board.
struct FlightSearchView: View {
    @Environment(BoardViewModel.self) private var board
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private struct Section: Identifiable {
        let airport: Airport
        let flights: [Flight]

        var id: String { airport.code }
    }

    private var results: [Flight] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = board.flights.filter { flight in
            guard flight.status != .departed else { return false }
            guard !trimmed.isEmpty else { return true }
            return [
                flight.number,
                flight.origin.code,
                flight.origin.city,
                flight.destination.code,
                flight.destination.city,
                flight.gate
            ].contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
        return matches.sorted { $0.displayTime < $1.displayTime }
    }

    private var sections: [Section] {
        board.airports.compactMap { airport in
            let flights = results.filter { $0.origin == airport }
            return flights.isEmpty ? nil : Section(airport: airport, flights: flights)
        }
    }

    var body: some View {
        List {
            searchField
                .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            if results.isEmpty {
                ContentUnavailableView.search(text: query)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(sections) { section in
                    SwiftUI.Section {
                        ForEach(section.flights) { flight in
                            NavigationLink {
                                FlightDetailView(flight: board.flight(withID: flight.id) ?? flight)
                            } label: {
                                SearchResultRow(flight: flight)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("\(section.airport.city) · \(section.airport.code)")
                            .themeFont(11, weight: .bold, design: .rounded)
                            .tracking(1.2)
                            .foregroundStyle(Theme.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .tint(Theme.teal)
        .scrollContentBackground(.hidden)
        .background(Theme.routeGradient.ignoresSafeArea())
        .navigationTitle("Find a flight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await board.load() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .themeFont(13, weight: .semibold, design: .default)
                .foregroundStyle(Theme.secondary)

            TextField("Flight number, city or gate", text: $query)
                .themeFont(14, design: .rounded)
                .foregroundStyle(Theme.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searchFocused)
                .accessibilityIdentifier("search-field")

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }
}

private struct SearchResultRow: View {
    let flight: Flight

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(flight.number)
                        .themeFont(11, weight: .semibold, design: .monospaced)
                        .foregroundStyle(Theme.secondary)

                    Text("\(flight.origin.code) → \(flight.destination.code)")
                        .themeFont(11, weight: .bold, design: .rounded)
                        .foregroundStyle(Theme.teal)
                }

                Text(flight.destination.city)
                    .themeFont(18, weight: .semibold, design: .rounded)
                    .foregroundStyle(Theme.primary)

                Text("Gate \(flight.gate) · \(flight.terminal)")
                    .themeFont(11, design: .rounded)
                    .foregroundStyle(Theme.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(flight.displayTime.formatted(date: .omitted, time: .shortened))
                    .themeFont(18, weight: .semibold, design: .rounded)
                    .monospacedDigit()
                    .foregroundStyle(Theme.primary)

                StatusPill(status: flight.status)
            }
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(flight.number), \(flight.origin.city) to \(flight.destination.city), "
            + "\(flight.status.label), gate \(flight.gate)"
        )
    }
}

#Preview {
    NavigationStack {
        FlightSearchView()
    }
    .environment(BoardViewModel())
}
