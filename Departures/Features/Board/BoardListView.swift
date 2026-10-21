import SwiftUI

/// The board itself. Lives in the sidebar column on iPad and at the root of the
/// stack on iPhone, so it takes an optional selection rather than owning the
/// navigation container.
struct BoardListView: View {
    var selection: Binding<Flight.ID?>?

    @Environment(BoardViewModel.self) private var model
    @Environment(SavedFlights.self) private var saved
    @AppStorage("autoRefresh") private var autoRefresh = true
    @State private var showingAirports = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var model = model

        List(selection: selection) {
            header
                .rowChrome()

            filters
                .rowChrome()

            searchField(query: $model.query)
                .rowChrome()

            if let message = model.errorMessage {
                errorBanner(message)
                    .rowChrome()
            }

            if model.isLoading {
                loadingRows
            } else if model.visibleFlights.isEmpty {
                emptyState
                    .rowChrome()
            } else {
                ForEach(model.visibleFlights) { flight in
                    row(flight)
                        .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            freshnessNote
                .rowChrome()
        }
        .listStyle(.plain)
        .tint(Theme.teal)
        .accessibilityIdentifier("board-list")
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(Theme.routeGradient.ignoresSafeArea())
        .refreshable { await model.refresh() }
        .animation(.smooth(duration: 0.28), value: model.filter)
        .animation(.smooth(duration: 0.28), value: model.airport)
        .sheet(isPresented: $showingAirports) {
            AirportsView()
        }
        .task(id: autoRefresh) {
            guard autoRefresh else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                await model.refresh()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("DEPARTURES")
                        .themeFont(11, weight: .bold, design: .rounded)
                        .tracking(2.4)
                        .foregroundStyle(Theme.teal)

                    if model.isShowingCachedData {
                        Text("CACHED")
                            .themeFont(9, weight: .bold, design: .rounded)
                            .tracking(0.8)
                            .foregroundStyle(Theme.amber)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Theme.amber.opacity(0.12), in: .capsule)
                            .accessibilityIdentifier("cached-badge")
                    }
                }

                Text(model.airport.city)
                    .themeFont(34, weight: .bold, design: .rounded)
                    .foregroundStyle(Theme.primary)

                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .themeFont(13, design: .rounded)
                    .foregroundStyle(Theme.secondary)
            }

            Spacer()

            Button {
                showingAirports = true
            } label: {
                Text(model.airport.code)
                    .themeFont(20, weight: .heavy, design: .monospaced)
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("airport-picker")
            .accessibilityLabel("Change departure airport. Now \(model.airport.city).")
        }
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var filters: some View {
        HStack(spacing: 8) {
            ForEach(BoardViewModel.Filter.allCases) { filter in
                let isSelected = model.filter == filter
                Button {
                    model.filter = filter
                } label: {
                    Text(filter.rawValue)
                        .themeFont(13, weight: .semibold, design: .rounded)
                        .foregroundStyle(isSelected ? Theme.ink : Theme.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.primary : Color.white.opacity(0.05), in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("filter-\(filter.rawValue)")
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func searchField(query: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .themeFont(13, weight: .semibold, design: .default)
                .foregroundStyle(Theme.secondary)

            TextField("Flight, city or gate", text: query)
                .themeFont(14, design: .rounded)
                .foregroundStyle(Theme.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)
                .accessibilityIdentifier("board-search")

            if !query.wrappedValue.isEmpty {
                Button {
                    query.wrappedValue = ""
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
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func row(_ flight: Flight) -> some View {
        if let selection {
            BoardRow(flight: flight)
                .tag(flight.id)
                .contextMenu { saveButton(flight) }
                .accessibilityIdentifier("flight-row-\(flight.number)")
        } else {
            NavigationLink(value: flight) {
                BoardRow(flight: flight)
            }
            .buttonStyle(.plain)
            .contextMenu { saveButton(flight) }
            .accessibilityIdentifier("flight-row-\(flight.number)")
        }
    }

    private func saveButton(_ flight: Flight) -> some View {
        Button(
            saved.contains(flight.number) ? "Remove from saved" : "Save flight",
            systemImage: saved.contains(flight.number) ? "star.slash" : "star"
        ) {
            saved.toggle(flight.number)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(Theme.amber)
            Text(message)
                .themeFont(12, design: .rounded)
                .foregroundStyle(Theme.primary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.amber.opacity(0.10), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.amber.opacity(0.28), lineWidth: 1))
        .accessibilityIdentifier("error-banner")
    }

    private var loadingRows: some View {
        ForEach(0..<4, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .frame(height: 86)
                .overlay(alignment: .leading) {
                    ProgressView()
                        .tint(Theme.secondary)
                        .padding(.leading, 18)
                }
                .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 30))
                .foregroundStyle(Theme.secondary)
            Text(emptyTitle)
                .themeFont(15, weight: .semibold, design: .rounded)
                .foregroundStyle(Theme.primary)
            Text("Try a flight number, city or gate.")
                .themeFont(13, design: .rounded)
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptyTitle: String {
        if !model.query.isEmpty {
            return "No match for \(model.query)"
        }
        return model.filter == .delayed
            ? "Everything is on time at \(model.airport.code)"
            : "Nothing on the board"
    }

    private var freshnessNote: some View {
        Group {
            if let updated = model.lastUpdated {
                Text(
                    model.isShowingCachedData
                        ? "Cached · updated \(updated.formatted(date: .omitted, time: .shortened))"
                        : "Live · updated \(updated.formatted(date: .omitted, time: .shortened))"
                )
                .themeFont(11, design: .rounded)
                .foregroundStyle(Theme.secondary.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
                .padding(.bottom, 28)
                .accessibilityIdentifier("freshness")
            }
        }
    }
}

private extension View {
    func rowChrome() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

#Preview {
    NavigationStack {
        BoardListView()
    }
    .environment(BoardViewModel())
    .environment(SavedFlights())
}
