import SwiftUI
import struct WooFoundation.IndefiniteCircularProgressViewStyle

struct POSProgressViewStyle: ProgressViewStyle {
    let size: CGFloat
    let lineWidth: CGFloat
    let arcColor: Color

    init(size: CGFloat = 108, lineWidth: CGFloat = 48, arcColor: Color = .posPrimary) {
        self.size = size
        self.lineWidth = lineWidth
        self.arcColor = arcColor
    }

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            POSChaseLoaderView(size: size,
                               lineWidth: lineWidth,
                               arcColor: arcColor,
                               ringColor: .posSecondary)
            configuration.label
        }
        .accessibilityLabel(IndefiniteCircularProgressViewStyle.Localization.inProgressAccessibilityLabel)
    }
}

private struct POSChaseLoaderView: View {
    let size: CGFloat
    let lineWidth: CGFloat
    let arcColor: Color
    let ringColor: Color

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let progress = POSChaseMotion.cycleProgress(elapsed: timeline.date.timeIntervalSince(startDate))
            ZStack {
                Circle()
                    .stroke(ringColor, lineWidth: lineWidth)
                POSChaseArc(startDegrees: POSChaseMotion.tailAngle(progress: progress),
                            endDegrees: POSChaseMotion.headAngle(progress: progress))
                    .stroke(arcColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            }
        }
        .frame(width: size, height: size)
    }
}

private enum POSChaseMotion {
    static let cycleDuration: TimeInterval = 1.64
    static let startAngle: Double = -90
    static let minSweep: Double = 70
    static let travel: Double = 180
    static let easing = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.6, y: 0),
                                         endControlPoint: UnitPoint(x: 0.25, y: 1))

    static func cycleProgress(elapsed: TimeInterval) -> Double {
        let cycles = max(elapsed, 0) / cycleDuration
        return cycles - cycles.rounded(.down)
    }

    static func headAngle(progress: Double) -> Double {
        baseAngle(progress: progress) + minSweep + travel * ease(2 * progress)
    }

    static func tailAngle(progress: Double) -> Double {
        baseAngle(progress: progress) + travel * ease(2 * progress - 1)
    }

    private static func baseAngle(progress: Double) -> Double {
        startAngle + (360 - travel) * progress
    }

    private static func ease(_ value: Double) -> Double {
        easing.value(at: min(max(value, 0), 1))
    }
}

private struct POSChaseArc: Shape {
    let startDegrees: Double
    let endDegrees: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(startDegrees),
                    endAngle: .degrees(endDegrees),
                    clockwise: false)
        return path
    }
}

#if DEBUG
#Preview("POSProgressViewStyle") {
    ProgressView()
        .progressViewStyle(POSProgressViewStyle())
}
#endif
