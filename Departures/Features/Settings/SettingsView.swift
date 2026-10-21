import SwiftUI

struct SettingsView: View {
    let service: DemoFlightService

    @Environment(BoardViewModel.self) private var board
    @Environment(SavedFlights.self) private var saved
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoRefresh") private var autoRefresh = true
    @State private var isOffline = false
    @State private var isRefreshing = false
    @State private var showingAirports = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Board") {
                    Toggle("Refresh every minute", isOn: $autoRefresh)
                        .accessibilityIdentifier("auto-refresh-toggle")

                    Button {
                        Task { await refreshNow() }
                    } label: {
                        Label("Refresh now", systemImage: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("refresh-now")
                    .disabled(isRefreshing)
                }

                Section("Airport") {
                    LabeledContent("Departure board", value: "\(board.airport.city) (\(board.airport.code))")

                    Button {
                        showingAirports = true
                    } label: {
                        Label("Change airport", systemImage: "arrow.left.arrow.right")
                    }
                    .accessibilityIdentifier("settings-change-airport")
                }

                Section {
                    Toggle("Simulate offline", isOn: $isOffline)
                        .accessibilityIdentifier("offline-toggle")
                        .onChange(of: isOffline) { _, offline in
                            Task {
                                await service.setOffline(offline)
                                await board.refresh()
                            }
                        }

                    Button {
                        Task {
                            _ = await service.simulateGateChange()
                            await board.refresh()
                        }
                    } label: {
                        Label("Change NZ 103 gate", systemImage: "arrow.triangle.swap")
                    }
                    .accessibilityIdentifier("gate-change")
                } header: {
                    Text("Demo controls")
                } footer: {
                    Text("Offline uses the last saved snapshot. Gate changes apply on the next refresh.")
                }

                Section("Saved") {
                    LabeledContent("Saved flights", value: "\(saved.numbers.count)")

                    Button("Clear saved flights", role: .destructive) {
                        saved.removeAll()
                    }
                    .disabled(saved.numbers.isEmpty)
                }

                Section("About") {
                    LabeledContent("Version", value: version)
                    LabeledContent("Data", value: "Demo snapshot")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.routeGradient.ignoresSafeArea())
            .navigationTitle("Settings")
            .tint(Theme.teal)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(Theme.teal)
                        .accessibilityIdentifier("settings-done")
                }
            }
            .sheet(isPresented: $showingAirports) {
                AirportsView()
            }
            .task { isOffline = await service.isCurrentlyOffline() }
        }
        .preferredColorScheme(.dark)
    }

    private func refreshNow() async {
        isRefreshing = true
        await board.refresh()
        isRefreshing = false
    }
}

#Preview {
    SettingsView(service: DemoFlightService())
        .environment(BoardViewModel())
        .environment(SavedFlights())
}
