import SwiftUI

// MARK: - Progress View Style

public struct IndefiniteCircularProgressViewStyle: ProgressViewStyle {
    public var size: CGFloat
    public var lineWidth: CGFloat
    public var lineCap: CGLineCap
    public var circleColor: Color
    public var fillColor: Color

    private let cycleDuration: Double = 1.6

    public init(
        size: CGFloat,
        lineWidth: CGFloat = Constants.lineWidth,
        lineCap: CGLineCap = .round,
        circleColor: Color? = nil,
        fillColor: Color? = nil
    ) {
        self.size = size
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.circleColor = circleColor ?? Color(.primaryButtonBackground).opacity(Constants.backgroundOpacity)
        self.fillColor = fillColor ?? Color(.primaryButtonBackground)
    }

    public func makeBody(configuration: ProgressViewStyleConfiguration) -> some View {
        VStack {
            SpinnerView(
                size: size,
                lineWidth: lineWidth,
                lineCap: lineCap,
                circleColor: circleColor,
                fillColor: fillColor,
                cycleDuration: cycleDuration
            )
            configuration.label
        }
        .accessibilityLabel(Localization.inProgressAccessibilityLabel)
    }
}

// MARK: - Spinner View

/// Self-contained spinner using `AnimatableShape` for render-thread interpolation
/// and structured concurrency (.task) instead of Timer.
private struct SpinnerView: View {
    let size: CGFloat
    let lineWidth: CGFloat
    let lineCap: CGLineCap
    let circleColor: Color
    let fillColor: Color
    let cycleDuration: Double

    @State private var arcEnd: Double = Constants.initialArcEnd
    @State private var arcRotation: Angle = .zero
    @State private var globalRotation: Angle = .zero

    typealias Constants = IndefiniteCircularProgressViewStyle.Constants

    var body: some View {
        SpinnerShape(arcStart: Constants.initialArcStart, arcEnd: arcEnd)
            .stroke(fillColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
            .frame(width: size, height: size)
            .background(
                Circle().stroke(circleColor, lineWidth: lineWidth)
            )
            .rotationEffect(globalRotation + arcRotation)
            .onAppear {
                withAnimation(
                    .linear(duration: cycleDuration * 8)
                    .repeatForever(autoreverses: false)
                ) {
                    globalRotation = Constants.fullRotation
                }
            }
            .task {
                await runArcCycle()
            }
    }

    @MainActor
    private func runArcCycle() async {
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: cycleDuration / 2)) {
                arcEnd = Constants.fullCircle
            }
            withAnimation(.easeOut(duration: cycleDuration).delay(cycleDuration / 4)) {
                arcEnd = Constants.initialArcEnd
                arcRotation += Constants.fullRotation
            }
            try? await Task.sleep(for: .seconds(cycleDuration))
        }
    }
}

// MARK: - Shape

/// Trimmed circle arc. Exposes `animatableData` so SwiftUI interpolates
/// the path on the render thread without re-evaluating the view body.
private struct SpinnerShape: Shape {
    var arcStart: Double
    var arcEnd: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { .init(arcStart, arcEnd) }
        set {
            arcStart = newValue.first
            arcEnd = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(360 * arcStart - 90),
            endAngle: .degrees(360 * arcEnd - 90),
            clockwise: false
        )
        return path
    }
}

// MARK: - Constants & Localization

public extension IndefiniteCircularProgressViewStyle {
    enum Constants {
        public static let lineWidth: CGFloat = 10.0
        public static let backgroundOpacity: CGFloat = 0.2

        public static let initialArcStart: Double = 0
        public static let initialArcEnd: Double = 0.05
        public static let fullCircle: Double = 1

        public static let fullRotation: Angle = .radians(.pi * 2)
    }

    enum Localization {
        public static let inProgressAccessibilityLabel = NSLocalizedString(
            "In progress",
            comment: "Accessibility label for an indeterminate loading indicator"
        )
    }
}
