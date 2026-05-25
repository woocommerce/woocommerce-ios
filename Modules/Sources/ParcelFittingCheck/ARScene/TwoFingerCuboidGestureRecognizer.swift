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
