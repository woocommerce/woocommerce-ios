import Foundation
import Testing
@testable import ParcelFittingCheck

@Suite("TwoFingerTracker")
struct TwoFingerTrackerTests {

    @Suite("begin")
    struct Begin {

        @Test
        func test_begin_when_two_points_then_records_locations() {
            // Given
            var sut = TwoFingerTracker()
            let first = CGPoint(x: 200, y: 200)
            let second = CGPoint(x: 300, y: 200)

            // When
            sut.begin(first: first, second: second)

            // Then
            #expect(sut.mode == .undecided)
            #expect(sut.startLocations.first == first)
            #expect(sut.startLocations.second == second)
            #expect(sut.currentLocations.first == first)
            #expect(sut.currentLocations.second == second)
        }
    }

    @Suite("Mode detection — resize enabled")
    struct ModeDetectionResizeEnabled {

        @Test
        func test_update_when_pure_pinch_then_mode_becomes_resize() {
            // Given
            var sut = TwoFingerTracker()
            sut.begin(first: CGPoint(x: 200, y: 200), second: CGPoint(x: 300, y: 200))

            // When — pinch out by 50 pts (well past 36 pts dominance threshold)
            sut.update(first: CGPoint(x: 200, y: 200), second: CGPoint(x: 350, y: 200), isResizeEnabled: true)

            // Then
            #expect(sut.mode == .resize)
        }

        @Test
        func test_update_when_pinch_dominant_and_rotation_crossed_then_mode_becomes_resize() {
            // Given
            var sut = TwoFingerTracker()
            let origin = CGPoint(x: 200, y: 200)
            sut.begin(first: origin, second: CGPoint(x: 300, y: 200))

            // When — pinch to 150 pts (delta 50, beyond the 36 pts dominance line)
            // while rotating 12° (above the 8° angle threshold). Distance must win.
            sut.update(first: origin, second: rotated(from: origin, radius: 150, byDegrees: 12), isResizeEnabled: true)

            // Then
            #expect(sut.mode == .resize)
        }

        @Test
        func test_update_when_pinch_modest_and_rotation_crossed_then_mode_becomes_rotate() {
            // Given
            var sut = TwoFingerTracker()
            let origin = CGPoint(x: 200, y: 200)
            sut.begin(first: origin, second: CGPoint(x: 300, y: 200))

            // When — pinch to 130 pts (delta 30, above 24 pts but below the 36 pts
            // dominance line) while rotating 12°. Rotation should win.
            sut.update(first: origin, second: rotated(from: origin, radius: 130, byDegrees: 12), isResizeEnabled: true)

            // Then
            #expect(sut.mode == .rotate)
        }
    }

    @Suite("Mode detection — resize disabled")
    struct ModeDetectionResizeDisabled {

        @Test
        func test_update_when_pure_pinch_and_resize_disabled_then_mode_stays_undecided() {
            // Given
            var sut = TwoFingerTracker()
            sut.begin(first: CGPoint(x: 200, y: 200), second: CGPoint(x: 300, y: 200))

            // When — pinch out by 80 pts (would be a clear resize when enabled).
            sut.update(first: CGPoint(x: 200, y: 200), second: CGPoint(x: 380, y: 200), isResizeEnabled: false)

            // Then
            #expect(sut.mode == .undecided)
        }

        @Test
        func test_update_when_pinch_dominant_and_rotation_crossed_and_resize_disabled_then_mode_becomes_rotate() {
            // Given
            var sut = TwoFingerTracker()
            let origin = CGPoint(x: 200, y: 200)
            sut.begin(first: origin, second: CGPoint(x: 300, y: 200))

            // When
            sut.update(first: origin, second: rotated(from: origin, radius: 150, byDegrees: 12), isResizeEnabled: false)

            // Then
            #expect(sut.mode == .rotate)
        }
    }

    @Suite("Mode persistence")
    struct ModePersistence {

        @Test
        func test_update_when_mode_resize_then_subsequent_rotation_keeps_resize() {
            // Given
            var sut = TwoFingerTracker()
            let origin = CGPoint(x: 200, y: 200)
            sut.begin(first: origin, second: CGPoint(x: 300, y: 200))

            // Lock into resize with a clean pinch.
            sut.update(first: origin, second: CGPoint(x: 360, y: 200), isResizeEnabled: true)
            #expect(sut.mode == .resize)

            // When — rotate hard while keeping the same separation.
            sut.update(first: origin, second: rotated(from: origin, radius: 160, byDegrees: 30), isResizeEnabled: true)

            // Then
            #expect(sut.mode == .resize)
        }
    }

    @Suite("Rotation tracking")
    struct RotationTracking {

        @Test
        func test_update_when_rotation_crosses_pi_then_normalizes_to_short_path() {
            // Given — fingers initially aligned at +170°.
            var sut = TwoFingerTracker()
            let origin = CGPoint(x: 200, y: 200)
            sut.begin(first: origin, second: rotated(from: origin, radius: 100, byDegrees: 170))

            // When — rotate by +20° to land at +190°, which raw atan2 reports as -170°.
            sut.update(first: origin, second: rotated(from: origin, radius: 100, byDegrees: 190), isResizeEnabled: true)

            // Then — short-path rotation is +20°, not -340°.
            #expect(approxEqual(sut.rotationFromStart, .pi * 20 / 180, tolerance: 0.001))
            #expect(sut.mode == .rotate)
        }
    }

    @Suite("reset")
    struct Reset {

        @Test
        func test_reset_then_clears_mode_locations_distance_and_rotation() {
            // Given — drive the tracker to a non-default state.
            var sut = TwoFingerTracker()
            let origin = CGPoint(x: 200, y: 200)
            sut.begin(first: origin, second: CGPoint(x: 300, y: 200))
            sut.update(first: origin, second: rotated(from: origin, radius: 150, byDegrees: 20), isResizeEnabled: true)
            #expect(sut.mode != .undecided)

            // When
            sut.reset()

            // Then
            #expect(sut.mode == .undecided)
            #expect(sut.startLocations.first == .zero)
            #expect(sut.startLocations.second == .zero)
            #expect(sut.currentLocations.first == .zero)
            #expect(sut.currentLocations.second == .zero)
            #expect(sut.rotationFromStart == 0)
            #expect(sut.distanceFromStart == 0)
        }
    }
}

// MARK: - Helpers

private func rotated(from origin: CGPoint, radius: CGFloat, byDegrees degrees: CGFloat) -> CGPoint {
    let radians = degrees * .pi / 180
    return CGPoint(x: origin.x + radius * cos(radians), y: origin.y + radius * sin(radians))
}

private func approxEqual<T: BinaryFloatingPoint>(_ a: T, _ b: T, tolerance: T = 0.01) -> Bool {
    abs(a - b) < tolerance
}
