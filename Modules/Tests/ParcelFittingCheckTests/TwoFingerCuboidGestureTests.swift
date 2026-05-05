import Foundation
import Testing
import UIKit
@testable import ParcelFittingCheck

@MainActor
@Suite("TwoFingerCuboidGesture")
struct TwoFingerCuboidGestureTests {

    @MainActor
    @Suite("touchesBegan")
    struct TouchesBegan {

        @Test
        func test_touchesBegan_when_one_finger_then_state_stays_possible() {
            // Given
            let context = TestContext()
            let touch = FakeUITouch(location: CGPoint(x: 100, y: 100))

            // When
            context.gesture.touchesBegan([touch], with: UIEvent())

            // Then
            #expect(context.gesture.state == .possible)
            #expect(context.gesture.mode == .undecided)
        }

        @Test
        func test_touchesBegan_when_two_fingers_then_state_began_and_locations_recorded() {
            // Given
            let context = TestContext()
            let firstStart = CGPoint(x: 200, y: 200)
            let secondStart = CGPoint(x: 300, y: 200)

            // When
            _ = context.lowerTwoFingers(at: firstStart, secondStart)

            // Then
            #expect(context.gesture.state == .began)
            #expect(context.gesture.mode == .undecided)
            #expect(context.gesture.startLocations.first == firstStart)
            #expect(context.gesture.startLocations.second == secondStart)
            #expect(context.gesture.currentLocations.first == firstStart)
            #expect(context.gesture.currentLocations.second == secondStart)
        }
    }

    @MainActor
    @Suite("Mode detection — resize enabled")
    struct ModeDetectionResizeEnabled {

        @Test
        func test_touchesMoved_when_pure_pinch_then_mode_becomes_resize() {
            // Given
            let context = TestContext(isResizeEnabled: true)
            let (t0, t1) = context.lowerTwoFingers(
                at: CGPoint(x: 200, y: 200),
                CGPoint(x: 300, y: 200)
            )

            // When — pinch out by 50 pts (well past 36 pts dominance threshold)
            context.move(t0, to: CGPoint(x: 200, y: 200), t1, to: CGPoint(x: 350, y: 200))

            // Then
            #expect(context.gesture.mode == .resize)
            #expect(context.gesture.state == .changed)
        }

        @Test
        func test_touchesMoved_when_pinch_dominant_and_rotation_crossed_then_mode_becomes_resize() {
            // Given
            let context = TestContext(isResizeEnabled: true)
            let origin = CGPoint(x: 200, y: 200)
            let (t0, t1) = context.lowerTwoFingers(at: origin, CGPoint(x: 300, y: 200))

            // When — pinch to 150 pts (delta 50, beyond the 36 pts dominance line)
            // while rotating 12° (above the 8° angle threshold). Distance must win.
            context.move(t0, to: origin, t1, to: rotated(from: origin, radius: 150, byDegrees: 12))

            // Then
            #expect(context.gesture.mode == .resize)
        }

        @Test
        func test_touchesMoved_when_pinch_modest_and_rotation_crossed_then_mode_becomes_rotate() {
            // Given
            let context = TestContext(isResizeEnabled: true)
            let origin = CGPoint(x: 200, y: 200)
            let (t0, t1) = context.lowerTwoFingers(at: origin, CGPoint(x: 300, y: 200))

            // When — pinch to 130 pts (delta 30, above 24 pts but below the 36 pts
            // dominance line) while rotating 12°. Rotation should win.
            context.move(t0, to: origin, t1, to: rotated(from: origin, radius: 130, byDegrees: 12))

            // Then
            #expect(context.gesture.mode == .rotate)
        }
    }

    @MainActor
    @Suite("Mode detection — resize disabled")
    struct ModeDetectionResizeDisabled {

        @Test
        func test_touchesMoved_when_pure_pinch_and_resize_disabled_then_mode_stays_undecided() {
            // Given
            let context = TestContext(isResizeEnabled: false)
            let (t0, t1) = context.lowerTwoFingers(
                at: CGPoint(x: 200, y: 200),
                CGPoint(x: 300, y: 200)
            )

            // When — pinch out by 80 pts (would be a clear resize when enabled).
            context.move(t0, to: CGPoint(x: 200, y: 200), t1, to: CGPoint(x: 380, y: 200))

            // Then
            #expect(context.gesture.mode == .undecided)
        }

        @Test
        func test_touchesMoved_when_pinch_dominant_and_rotation_crossed_and_resize_disabled_then_mode_becomes_rotate() {
            // Given — same input as the "resize wins" case above, but resize is gated off.
            let context = TestContext(isResizeEnabled: false)
            let origin = CGPoint(x: 200, y: 200)
            let (t0, t1) = context.lowerTwoFingers(at: origin, CGPoint(x: 300, y: 200))

            // When
            context.move(t0, to: origin, t1, to: rotated(from: origin, radius: 150, byDegrees: 12))

            // Then
            #expect(context.gesture.mode == .rotate)
        }
    }

    @MainActor
    @Suite("Mode persistence")
    struct ModePersistence {

        @Test
        func test_touchesMoved_when_mode_resize_then_subsequent_rotation_keeps_resize() {
            // Given
            let context = TestContext(isResizeEnabled: true)
            let origin = CGPoint(x: 200, y: 200)
            let (t0, t1) = context.lowerTwoFingers(at: origin, CGPoint(x: 300, y: 200))

            // Lock into resize with a clean pinch.
            context.move(t0, to: origin, t1, to: CGPoint(x: 360, y: 200))
            #expect(context.gesture.mode == .resize)

            // When — rotate hard while keeping the same separation.
            context.move(t0, to: origin, t1, to: rotated(from: origin, radius: 160, byDegrees: 30))

            // Then — the `if mode == .undecided` guard prevents mode flipping.
            #expect(context.gesture.mode == .resize)
        }
    }

    @MainActor
    @Suite("Rotation tracking")
    struct RotationTracking {

        @Test
        func test_touchesMoved_when_rotation_crosses_pi_then_normalizes_to_short_path() {
            // Given — fingers initially aligned at +170°.
            let context = TestContext()
            let origin = CGPoint(x: 200, y: 200)
            let (t0, t1) = context.lowerTwoFingers(
                at: origin,
                rotated(from: origin, radius: 100, byDegrees: 170)
            )

            // When — rotate by +20° to land at +190°, which raw atan2 reports as -170°.
            context.move(t0, to: origin, t1, to: rotated(from: origin, radius: 100, byDegrees: 190))

            // Then — short-path rotation is +20°, not -340°.
            #expect(approxEqual(context.gesture.rotationFromStart, .pi * 20 / 180, tolerance: 0.001))
            #expect(context.gesture.mode == .rotate)
        }
    }

    @MainActor
    @Suite("touchesEnded")
    struct TouchesEnded {

        @Test
        func test_touchesEnded_when_one_finger_lifts_with_undecided_mode_then_gesture_terminates_without_recognition() {
            // Given — a two-finger gesture cannot continue with a single finger,
            // so any finger lift terminates the gesture.
            let context = TestContext()
            let (t0, _) = context.lowerTwoFingers(
                at: CGPoint(x: 200, y: 200),
                CGPoint(x: 300, y: 200)
            )

            // When
            context.gesture.touchesEnded([t0], with: UIEvent())

            // Then — the gesture wanted .failed, but UIKit coerces .began -> .failed
            // into .began -> .cancelled. Either way the gesture did not recognize.
            #expect(context.gesture.state.isTerminalUnrecognized)
        }

        @Test
        func test_touchesEnded_when_finger_lifts_after_mode_locks_then_state_ended() {
            // Given
            let context = TestContext()
            let origin = CGPoint(x: 200, y: 200)
            let (t0, t1) = context.lowerTwoFingers(at: origin, CGPoint(x: 300, y: 200))
            // Lock into rotate.
            context.move(t0, to: origin, t1, to: rotated(from: origin, radius: 100, byDegrees: 15))
            #expect(context.gesture.mode == .rotate)

            // When
            context.gesture.touchesEnded([t0, t1], with: UIEvent())

            // Then
            #expect(context.gesture.state == .ended)
        }
    }

    @MainActor
    @Suite("touchesCancelled")
    struct TouchesCancelled {

        @Test
        func test_touchesCancelled_then_state_becomes_cancelled() {
            // Given
            let context = TestContext()
            let (t0, t1) = context.lowerTwoFingers(
                at: CGPoint(x: 200, y: 200),
                CGPoint(x: 300, y: 200)
            )

            // When
            context.gesture.touchesCancelled([t0, t1], with: UIEvent())

            // Then
            #expect(context.gesture.state == .cancelled)
        }
    }

    @MainActor
    @Suite("reset")
    struct Reset {

        @Test
        func test_reset_then_clears_mode_locations_distance_and_rotation() {
            // Given — drive the gesture to a non-default state.
            let context = TestContext()
            let origin = CGPoint(x: 200, y: 200)
            let (t0, t1) = context.lowerTwoFingers(at: origin, CGPoint(x: 300, y: 200))
            context.move(t0, to: origin, t1, to: rotated(from: origin, radius: 150, byDegrees: 20))
            context.gesture.touchesEnded([t0, t1], with: UIEvent())
            #expect(context.gesture.mode != .undecided)

            // When
            context.gesture.reset()

            // Then
            #expect(context.gesture.mode == .undecided)
            #expect(context.gesture.startLocations.first == .zero)
            #expect(context.gesture.startLocations.second == .zero)
            #expect(context.gesture.currentLocations.first == .zero)
            #expect(context.gesture.currentLocations.second == .zero)
            #expect(context.gesture.rotationFromStart == 0)
            #expect(context.gesture.distanceFromStart == 0)
        }
    }
}

// MARK: - Test helpers

/// Stages a `TwoFingerCuboidGesture` attached to a fresh view and exposes
/// helpers for driving touches with stubbed locations.
@MainActor
private final class TestContext {
    let view: UIView
    let gesture: TwoFingerCuboidGesture

    init(isResizeEnabled: Bool = true) {
        view = UIView(frame: CGRect(x: 0, y: 0, width: 2000, height: 2000))
        gesture = TwoFingerCuboidGesture(target: nil, action: nil)
        gesture.isResizeEnabled = isResizeEnabled
        view.addGestureRecognizer(gesture)
    }

    /// Sends two touches one at a time so the gesture's tracked-touches order
    /// is deterministic (first touch -> trackedTouches[0]).
    @discardableResult
    func lowerTwoFingers(at first: CGPoint, _ second: CGPoint) -> (FakeUITouch, FakeUITouch) {
        let t0 = FakeUITouch(location: first)
        let t1 = FakeUITouch(location: second)
        gesture.touchesBegan([t0], with: UIEvent())
        gesture.touchesBegan([t1], with: UIEvent())
        return (t0, t1)
    }

    /// Updates the stubbed locations on the existing tracked touches and fires
    /// a touchesMoved event. The gesture re-reads `location(in:)` from its
    /// tracked touches, so the set passed in is incidental.
    func move(
        _ t0: FakeUITouch, to p0: CGPoint,
        _ t1: FakeUITouch, to p1: CGPoint
    ) {
        t0.set(location: p0)
        t1.set(location: p1)
        gesture.touchesMoved([t0, t1], with: UIEvent())
    }
}

/// Drop-in replacement for `UITouch` whose `location(in:)` returns whatever
/// the test sets. Subclassing `UITouch` is unusual but works for unit tests
/// because the gesture only consults `location(in:)`.
private final class FakeUITouch: UITouch {
    private var stubbedLocation: CGPoint

    init(location: CGPoint) {
        stubbedLocation = location
        super.init()
    }

    func set(location: CGPoint) {
        stubbedLocation = location
    }

    override func location(in view: UIView?) -> CGPoint {
        stubbedLocation
    }
}

private func rotated(from origin: CGPoint, radius: CGFloat, byDegrees degrees: CGFloat) -> CGPoint {
    let radians = degrees * .pi / 180
    return CGPoint(x: origin.x + radius * cos(radians), y: origin.y + radius * sin(radians))
}

private func approxEqual<T: BinaryFloatingPoint>(_ a: T, _ b: T, tolerance: T = 0.01) -> Bool {
    abs(a - b) < tolerance
}

private extension UIGestureRecognizer.State {
    /// True when the gesture has terminated without recognizing a continuous
    /// gesture. Covers both `.failed` (rejected before recognition) and
    /// `.cancelled` (UIKit coerces a `.began -> .failed` transition into
    /// `.began -> .cancelled`, so the source's `.failed` intent surfaces here).
    var isTerminalUnrecognized: Bool {
        self == .failed || self == .cancelled
    }
}
