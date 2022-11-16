import SwiftUI

public struct IndefiniteCircularProgressViewStyle: ProgressViewStyle {
    var size: CGFloat
    private let arcStart: Double = Constants.initialArcStart
    private let animationDuration: Double = 1.6

    @State private var arcEnd: Double = Constants.initialArcEnd
    @State private var rotation: Angle = Constants.threeQuarterRotation
    @State private var viewRotation: Angle = .radians(0)
    @State private var arcTimer: Timer?

    public func makeBody(configuration: ProgressViewStyleConfiguration) -> some View {
        VStack {
            ZStack {
                progressCircleView()
                    .rotationEffect(viewRotation)
            }.padding()
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
    }

    private func progressCircleView() -> some View {
        Circle()
            .stroke(
                Color(.primary),
                lineWidth: Constants.lineWidth)
            .opacity(Constants.backgroundOpacity)
            .overlay(progressFill())
            .frame(width: size, height: size)
    }

    private func progressFill() -> some View {
        Circle()
            .trim(
                from: CGFloat(Constants.initialArcStart),
                to: CGFloat(arcEnd))
            .stroke(
                Color(.primary),
                style: StrokeStyle(lineWidth: Constants.lineWidth, lineCap: .round))
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

private extension IndefiniteCircularProgressViewStyle {
    enum Constants {
        static let lineWidth: CGFloat = 10.0
        static let backgroundOpacity: CGFloat = 0.2

        static let initialArcStart: Double = 0
        static let initialArcEnd: Double = 0.05
        static let fullCircle: Double = 1

        static let threeQuarterRotation: Angle = .radians((9 * Double.pi)/6)
        static let fullRotation: Angle = .radians(Double.pi * 2)
    }
}
