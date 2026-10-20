import SwiftUI

struct BoardView: View {
    @State private var model = BoardViewModel()
    @State private var path = NavigationPath()
    @Namespace private var pill

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.routeGradient.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        header
                        filters
                        searchField

                        if let message = model.errorMessage {
                            errorBanner(message)
                        }

                        if model.isLoading {
                            loadingRows
                        } else if model.visibleFlights.isEmpty {
                            emptyState
                        } else {
                            ForEach(model.visibleFlights) { flight in
                                NavigationLink(value: flight) {
                                    BoardRow(flight: flight)
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }

                        freshnessNote
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .refreshable { await model.refresh() }
                .animation(.smooth(duration: 0.28), value: model.filter)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Flight.self) { flight in
                FlightDetailView(flight: flight)
            }
            .task {
                await model.load()
                #if DEBUG
                // Screenshot/QA hook: open straight to a flight without tapping.
                if let number = ProcessInfo.processInfo.environment["OPEN_FLIGHT"],
                   let flight = model.flights.first(where: { $0.number == number }) {
                    path.append(flight)
                }
                #endif
            }
            .onOpenURL { url in
                guard
                    url.scheme == "departures",
                    url.host == "flight",
                    let number = url.pathComponents.dropFirst().first?.removingPercentEncoding,
                    let flight = model.flights.first(where: { $0.number == number })
                else { return }
                path.append(flight)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DEPARTURES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(Theme.teal)

                Text("Auckland")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primary)

                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.secondary)
            }

            Spacer()

            Text("AKL")
                .font(.system(size: 26, weight: .heavy, design: .monospaced))
                .foregroundStyle(Theme.primary.opacity(0.16))
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
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? Theme.ink : Theme.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Theme.primary)
                                    .matchedGeometryEffect(id: "filter", in: pill)
                            } else {
                                Capsule().fill(Color.white.opacity(0.05))
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.secondary)

            TextField("Flight, city or gate", text: $model.query)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !model.query.isEmpty {
                Button {
                    model.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondary)
                }
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

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(Theme.amber)
            Text(message)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Theme.primary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.amber.opacity(0.10), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.amber.opacity(0.28), lineWidth: 1))
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 30))
                .foregroundStyle(Theme.secondary)
            Text(model.query.isEmpty ? "Nothing on the board" : "No match for \(model.query)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primary)
            Text("Try a flight number, city or gate.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var freshnessNote: some View {
        Group {
            if let updated = model.lastUpdated {
                Text(
                    model.isShowingCachedData
                        ? "Cached · updated \(updated.formatted(date: .omitted, time: .shortened))"
                        : "Live · updated \(updated.formatted(date: .omitted, time: .shortened))"
                )
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Theme.secondary.opacity(0.7))
                .padding(.top, 10)
            }
        }
    }
}

#Preview {
    BoardView()
}
