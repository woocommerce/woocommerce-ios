import Foundation
import Testing
import UIKit
@testable import PointOfSale

@MainActor
struct POSLockPrivacyCoverTests {
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))

    @Test func test_inactive_snapshot_when_pos_is_locked_then_window_is_covered_synchronously() {
        // Given
        let session = MockPOSAccessSession(isLocked: false)
        let view = POSLockPrivacyCover.PrivacyView(session: session)
        window.addSubview(view)
        defer { view.removeCover() }
        session.isLocked = true

        // When
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)

        // Then
        let cover = window.subviews.last
        #expect(cover?.accessibilityIdentifier == "pos-lock-privacy-cover")
        #expect(cover?.frame == window.bounds)
        #expect(cover?.backgroundColor?.cgColor.alpha == 1)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        #expect(window.subviews.last === view)
    }

    @Test func test_inactive_snapshot_when_pos_is_unlocked_then_does_not_cover_the_window() {
        // Given
        let view = POSLockPrivacyCover.PrivacyView(session: MockPOSAccessSession(isLocked: false))
        window.addSubview(view)
        defer { view.removeCover() }

        // When
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)

        // Then
        #expect(window.subviews.last === view)
    }
}
