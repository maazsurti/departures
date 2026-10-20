import SwiftUI

struct FlightDetailView: View {
    let flight: Flight

    private var timeText: String {
        flight.displayTime.formatted(date: .omitted, time: .shortened)
    }

    private var scheduledText: String {
        flight.scheduled.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        ZStack {
            Theme.routeGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    routeHeader
                    if flight.delayMinutes > 0 || flight.gateChanged { changesBanner }
                    progressCard
                    detailsGrid
                    timeline
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var routeHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text(flight.number)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                StatusPill(status: flight.status)
            }

            HStack(alignment: .center, spacing: 12) {
                airportColumn(code: flight.origin.code, city: flight.origin.city, alignment: .leading)
                Spacer()
                Image(systemName: "airplane")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.teal)
                    .rotationEffect(.degrees(90))
                    .accessibilityHidden(true)
                Spacer()
                airportColumn(code: flight.destination.code, city: flight.destination.city, alignment: .trailing)
            }

            HStack {
                if flight.delayMinutes > 0 {
                    Text(scheduledText)
                        .strikethrough(color: Theme.secondary)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.secondary)
                    Text("→")
                        .foregroundStyle(Theme.secondary.opacity(0.6))
                    Text(timeText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.amber)
                } else {
                    Text(timeText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primary)
                }
            }
        }
    }

    private func airportColumn(code: String, city: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(code)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.primary)
            Text(city)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Theme.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var changesBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            if flight.delayMinutes > 0 {
                changeRow(
                    icon: "clock.badge.exclamationmark",
                    title: "Departure moved",
                    detail: "Now \(timeText), \(flight.delayMinutes) minutes later than scheduled."
                )
            }
            if let previous = flight.previousGate {
                changeRow(
                    icon: "arrow.triangle.swap",
                    title: "Gate changed",
                    detail: "Now gate \(flight.gate), was \(previous). Same terminal."
                )
            }
        }
        .padding(14)
        .background(Theme.amber.opacity(0.10), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Theme.amber.opacity(0.3), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func changeRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.amber)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primary)
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var progressCard: some View {
        VStack(spacing: 14) {
            FlightArc(progress: flight.progress, tint: Theme.statusColor(flight.status))
                .frame(height: 74)

            HStack {
                Text(flight.status == .departed ? "In the air" : "On the ground")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("\(Int(flight.progress * 100))% of route")
                    .font(.system(size: 12, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(18)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Flight progress, \(Int(flight.progress * 100)) percent of route complete")
    }

    private var detailsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                detailTile(title: "Gate", value: flight.gate, icon: "door.left.hand.open")
                detailTile(title: "Terminal", value: flight.terminal, icon: "building.2")
            }
            HStack(spacing: 12) {
                detailTile(title: "Aircraft", value: flight.aircraft, icon: "airplane")
                detailTile(title: "Boarding", value: boardingWindow, icon: "clock")
            }
        }
    }

    private var boardingWindow: String {
        let start = flight.scheduled.addingTimeInterval(-40 * 60)
        return start.formatted(date: .omitted, time: .shortened)
    }

    private func detailTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.9)
            }
            .foregroundStyle(Theme.secondary)

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardSurface()
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            timelineRow(title: "Scheduled", detail: scheduledText, isDone: true)
            timelineRow(title: "Boarding", detail: boardingWindow, isDone: flight.status == .boarding || flight.status == .departed)
            timelineRow(
                title: "Departed",
                detail: flight.status == .departed ? timeText : "—",
                isDone: flight.status == .departed,
                isLast: true
            )
        }
        .padding(18)
        .cardSurface()
    }

    private func timelineRow(title: String, detail: String, isDone: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isDone ? Theme.teal : Color.white.opacity(0.14))
                    .frame(width: 9, height: 9)
                    .overlay(
                        Circle().stroke(isDone ? Theme.teal.opacity(0.35) : .clear, lineWidth: 3)
                    )
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 9)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDone ? Theme.primary : Theme.secondary)
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.bottom, isLast ? 0 : 20)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        FlightDetailView(flight: PreviewData.flights[1])
    }
}
