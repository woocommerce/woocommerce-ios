import CoreGraphics

/// Pure-logic tracker for two-finger gesture mode detection, separated from
/// UIGestureRecognizer so it can be unit-tested without UIKit's touch pipeline.
struct TwoFingerTracker {
    enum Mode { case undecided, rotate, resize }

    private(set) var mode: Mode = .undecided
    private(set) var startLocations: (first: CGPoint, second: CGPoint) = (.zero, .zero)
    private(set) var currentLocations: (first: CGPoint, second: CGPoint) = (.zero, .zero)
    private(set) var rotationFromStart: CGFloat = 0
    private(set) var distanceFromStart: CGFloat = 0

    private var initialDistance: CGFloat = 0
    private var initialAngle: CGFloat = 0

    private enum Threshold {
        static let distancePoints: CGFloat = 24
        static let distanceFraction: CGFloat = 0.06
        static let angleRadians: CGFloat = 8 * .pi / 180
        static let pinchDominanceMultiplier: CGFloat = 1.5
    }

    mutating func begin(first: CGPoint, second: CGPoint) {
        startLocations = (first, second)
        currentLocations = (first, second)
        initialDistance = hypot(second.x - first.x, second.y - first.y)
        initialAngle = atan2(second.y - first.y, second.x - first.x)
    }

    mutating func update(first p0: CGPoint, second p1: CGPoint, isResizeEnabled: Bool) {
        currentLocations = (p0, p1)

        let currentDistance = hypot(p1.x - p0.x, p1.y - p0.y)
        let currentAngle = atan2(p1.y - p0.y, p1.x - p0.x)
        let angleDiff = currentAngle - initialAngle
        distanceFromStart = currentDistance - initialDistance
        rotationFromStart = atan2(sin(angleDiff), cos(angleDiff))

        if mode == .undecided {
            let angleCrossed = abs(rotationFromStart) > Threshold.angleRadians
            let distanceCrossed = isResizeEnabled
                && abs(distanceFromStart) > Threshold.distancePoints
                && abs(distanceFromStart) > Threshold.distanceFraction * initialDistance

            if distanceCrossed && (!angleCrossed || abs(distanceFromStart) >= Threshold.distancePoints * Threshold.pinchDominanceMultiplier) {
                mode = .resize
            } else if angleCrossed {
                mode = .rotate
            }
        }
    }

    mutating func reset() {
        mode = .undecided
        startLocations = (.zero, .zero)
        currentLocations = (.zero, .zero)
        rotationFromStart = 0
        distanceFromStart = 0
        initialDistance = 0
        initialAngle = 0
    }
}
