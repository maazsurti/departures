import SwiftUI

/// A deliberately simple arc: the plane travels along it, the completed part is
/// drawn in the status colour, and the rest stays muted. Geometry is computed in
/// `Canvas` so it does not allocate a view per pixel.
struct FlightArc: View {
    let progress: Double
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 10
            let rect = CGRect(
                x: inset,
                y: inset,
                width: size.width - inset * 2,
                height: (size.height - inset * 2) * 1.6
            )

            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.9)
            )

            context.stroke(
                path,
                with: .color(Color.white.opacity(0.12)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
            )

            let clamped = min(max(progress, 0), 1)
            let travelled = path.trimmedPath(from: 0, to: clamped)
            context.stroke(
                travelled,
                with: .color(tint),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )

            for (point, opacity) in [
                (CGPoint(x: rect.minX, y: rect.maxY), 0.9),
                (CGPoint(x: rect.maxX, y: rect.maxY), 0.9)
            ] {
                let dot = Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
                context.fill(dot, with: .color(Color.white.opacity(opacity)))
            }

            if let planePoint = travelled.currentPoint {
                let plane = Path(ellipseIn: CGRect(x: planePoint.x - 7, y: planePoint.y - 7, width: 14, height: 14))
                context.fill(plane, with: .color(tint.opacity(0.18)))
                let core = Path(ellipseIn: CGRect(x: planePoint.x - 4, y: planePoint.y - 4, width: 8, height: 8))
                context.fill(core, with: .color(tint))
            }
        }
        .animation(.smooth(duration: 0.6), value: progress)
    }
}

#Preview {
    ZStack {
        Theme.ink
        FlightArc(progress: 0.55, tint: Theme.teal)
            .frame(height: 80)
            .padding()
    }
}
