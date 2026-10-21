import SwiftUI

struct AirportsView: View {
    @Environment(BoardViewModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.airports.isEmpty {
                    ProgressView()
                        .tint(Theme.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(model.airports) { airport in
                                airportRow(airport)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } footer: {
                            Text("Departure boards are demo data.")
                                .themeFont(11, design: .rounded)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.routeGradient.ignoresSafeArea())
            .navigationTitle("Departure airport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(Theme.teal)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func airportRow(_ airport: Airport) -> some View {
        Button {
            model.airport = airport
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(airport.code)
                    .themeFont(18, weight: .heavy, design: .monospaced)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 52, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(airport.city)
                        .themeFont(16, weight: .semibold, design: .rounded)
                        .foregroundStyle(Theme.primary)
                    Text(airport.name)
                        .themeFont(12, design: .rounded)
                        .foregroundStyle(Theme.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(model.departureCount(for: airport))")
                        .themeFont(15, weight: .semibold, design: .rounded)
                        .monospacedDigit()
                        .foregroundStyle(Theme.primary)
                    Text("flights")
                        .themeFont(11, design: .rounded)
                        .foregroundStyle(Theme.secondary)
                }

                Image(systemName: model.airport == airport ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(model.airport == airport ? Theme.teal : Theme.secondary.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .cardSurface()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("airport-\(airport.code)")
        .accessibilityLabel("\(airport.city), \(airport.code), \(model.departureCount(for: airport)) flights")
        .accessibilityAddTraits(model.airport == airport ? .isSelected : [])
    }
}

#Preview {
    AirportsView()
        .environment(BoardViewModel())
}
