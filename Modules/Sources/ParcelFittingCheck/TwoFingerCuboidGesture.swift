import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Two-finger gesture that locks into either rotate or resize after the first
/// significant motion crosses a threshold. The mode persists until both fingers
/// lift, so a single pinch never mixes rotation and resize.
final class TwoFingerCuboidGesture: UIGestureRecognizer {
    enum Mode { case undecided, rotate, resize }

    var isResizeEnabled: Bool = true

    private(set) var mode: Mode = .undecided
    private(set) var startLocations: (first: CGPoint, second: CGPoint) = (.zero, .zero)
    private(set) var currentLocations: (first: CGPoint, second: CGPoint) = (.zero, .zero)
    private(set) var rotationFromStart: CGFloat = 0
    private(set) var distanceFromStart: CGFloat = 0

    private var trackedTouches: [UITouch] = []
    private var initialDistance: CGFloat = 0
    private var initialAngle: CGFloat = 0

    private enum Threshold {
        static let distancePoints: CGFloat = 24
        static let distanceFraction: CGFloat = 0.06
        static let angleRadians: CGFloat = 8 * .pi / 180
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view else { return }
        for touch in touches where trackedTouches.count < 2 && !trackedTouches.contains(where: { $0 === touch }) {
            trackedTouches.append(touch)
        }
        guard trackedTouches.count == 2 else { return }

        let p0 = trackedTouches[0].location(in: view)
        let p1 = trackedTouches[1].location(in: view)
        startLocations = (p0, p1)
        currentLocations = (p0, p1)
        initialDistance = hypot(p1.x - p0.x, p1.y - p0.y)
        initialAngle = atan2(p1.y - p0.y, p1.x - p0.x)
        state = .began
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view, trackedTouches.count == 2 else { return }
        guard state == .began || state == .changed else { return }

        let p0 = trackedTouches[0].location(in: view)
        let p1 = trackedTouches[1].location(in: view)
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

            if distanceCrossed && (!angleCrossed || abs(distanceFromStart) >= Threshold.distancePoints * 1.5) {
                mode = .resize
            } else if angleCrossed {
                mode = .rotate
            }
        }

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
        mode = .undecided
        trackedTouches.removeAll()
        startLocations = (.zero, .zero)
        currentLocations = (.zero, .zero)
        rotationFromStart = 0
        distanceFromStart = 0
        initialDistance = 0
        initialAngle = 0
    }
}
