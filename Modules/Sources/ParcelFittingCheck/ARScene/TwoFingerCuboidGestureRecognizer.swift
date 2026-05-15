import UIKit.UIGestureRecognizerSubclass

/// Two-finger gesture that locks into either rotate or resize after the first
/// significant motion crosses a threshold. The mode persists until both fingers
/// lift, so a single pinch never mixes rotation and resize.
final class TwoFingerCuboidGestureRecognizer: UIGestureRecognizer {

    var isResizeEnabled: Bool = true

    private(set) var tracker = TwoFingerTracker()

    var mode: TwoFingerTracker.Mode { tracker.mode }
    var startLocations: (first: CGPoint, second: CGPoint) { tracker.startLocations }
    var currentLocations: (first: CGPoint, second: CGPoint) { tracker.currentLocations }
    var rotationFromStart: CGFloat { tracker.rotationFromStart }
    var distanceFromStart: CGFloat { tracker.distanceFromStart }

    private var trackedTouches: [UITouch] = []

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        let countBefore = trackedTouches.count
        for touch in touches where trackedTouches.count < 2 && !trackedTouches.contains(where: { $0 === touch }) {
            trackedTouches.append(touch)
        }
        guard countBefore < 2, trackedTouches.count == 2 else { return }

        let p0 = trackedTouches[0].location(in: view)
        let p1 = trackedTouches[1].location(in: view)
        tracker.begin(first: p0, second: p1)
        state = .began
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard trackedTouches.count == 2 else { return }
        guard state == .began || state == .changed else { return }

        let p0 = trackedTouches[0].location(in: view)
        let p1 = trackedTouches[1].location(in: view)
        tracker.update(first: p0, second: p1, isResizeEnabled: isResizeEnabled)
        state = .changed
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches { trackedTouches.removeAll { $0 === touch } }
        if trackedTouches.count < 2 {
            state = (mode == .undecided) ? .failed : .ended
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }

    override func reset() {
        super.reset()
        tracker.reset()
        trackedTouches.removeAll()
    }
}

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
