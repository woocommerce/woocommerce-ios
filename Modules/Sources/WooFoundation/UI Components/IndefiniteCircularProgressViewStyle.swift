import SwiftUI

public struct IndefiniteCircularProgressViewStyle: ProgressViewStyle {
    public var size: CGFloat
    public var lineWidth: CGFloat = Constants.lineWidth
    public var lineCap: CGLineCap = .round
    public var circleColor: Color = Color(.primaryButtonBackground).opacity(Constants.backgroundOpacity)
    public var fillColor: Color = Color(.primaryButtonBackground)

    private let animationDuration: Double = 1.6

    @State private var arcEnd: Double = Constants.initialArcEnd
    @State private var rotation: Angle = Constants.threeQuarterRotation
    @State private var viewRotation: Angle = .radians(0)
    @State private var arcTimer: Timer?

    public init(size: CGFloat, lineWidth: CGFloat = Constants.lineWidth, lineCap: CGLineCap = .round, circleColor: Color? = nil, fillColor: Color? = nil) {
        self.size = size
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.circleColor = circleColor ?? Color(.primaryButtonBackground).opacity(Constants.backgroundOpacity)
        self.fillColor = fillColor ?? Color(.primaryButtonBackground)
    }

    public func makeBody(configuration: ProgressViewStyleConfiguration) -> some View {
        VStack {
            ZStack {
                progressCircleView()
                    .rotationEffect(viewRotation)
            }
            configuration.label
        }
        .onAppear() {
            animateArc()
            arcTimer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { _ in
                animateArc()
            }
            // Gradual rotation of the view to avoid the arc stopping and starting in the same place each spin.
            withAnimation(.linear(duration: animationDuration*8)
                .repeatForever(autoreverses: false)) {
                    viewRotation += Constants.fullRotation
                }
        }
        .onDisappear() {
            arcTimer?.invalidate()
        }
        .accessibilityLabel(Localization.inProgressAccessibilityLabel)
    }

    private func progressCircleView() -> some View {
        Circle()
            .stroke(
                circleColor,
                lineWidth: lineWidth)
            .overlay(progressFill())
            .frame(width: size, height: size)
    }

    private func progressFill() -> some View {
        Circle()
            .trim(
                from: CGFloat(Constants.initialArcStart),
                to: CGFloat(arcEnd))
            .stroke(
                fillColor,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
            .frame(width: size)
            .rotationEffect(rotation)
    }

    private func animateArc() {
        // Animate the end of the arc going to 100%
        withAnimation(
            .easeInOut(duration: animationDuration/2)) {
                arcEnd = Constants.fullCircle
            }
        // Halfway through the above, but slower, rotate the arc 1 turn, and move the end back to the start
        // This is a bit of a trick, and results in an apparently growing/shrinking arc around the circle.
        withAnimation(
            .easeOut(duration: animationDuration)
            .delay(animationDuration/4)) {
                arcEnd = Constants.initialArcEnd
                rotation += Constants.fullRotation
            }
    }
}

public extension IndefiniteCircularProgressViewStyle {
    enum Constants {
        public static let lineWidth: CGFloat = 10.0
        public static let backgroundOpacity: CGFloat = 0.2

        public static let initialArcStart: Double = 0
        public static let initialArcEnd: Double = 0.05
        public static let fullCircle: Double = 1

        public static let threeQuarterRotation: Angle = .radians((9 * Double.pi)/6)
        public static let fullRotation: Angle = .radians(Double.pi * 2)
    }

    enum Localization {
        public static let inProgressAccessibilityLabel = NSLocalizedString(
            "In progress",
            comment: "Accessibility label for an indeterminate loading indicator")
    }
}
