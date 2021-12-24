
import XCTest
import UIKit
@testable import WooCommerce

/// Tests for the concrete `KeyboardStateProvider`
///
final class KeyboardStateProviderTests: XCTestCase {
    func test_it_defaults_to_not_visible_and_no_frame() {
        let provider = KeyboardStateProvider()

        XCTAssertEqual(provider.state, KeyboardState(isVisible: false, frameEnd: .zero))
    }

    func test_it_updates_the_state_when_the_keyboard_is_about_to_be_shown() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        let expectedFrameEnd = CGRect(x: 1_981, y: 9_312, width: 311, height: 981)

        // Act
        notificationCenter.postKeyboardWillShowNotification(frameEnd: expectedFrameEnd)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: true, frameEnd: expectedFrameEnd))
    }

    func test_it_updates_the_state_when_the_keyboard_is_about_to_be_hidden() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        // Still using a dummy CGRect and not zero to test that KeyboardStateProvider uses the
        // frame given by the Notification
        let expectedFrameEnd = CGRect(x: 981, y: 5_135, width: 146, height: 561)

        // Act
        notificationCenter.postKeyboardWillHideNotification(frameEnd: expectedFrameEnd)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: false, frameEnd: expectedFrameEnd))
    }

    /// Test receiving multiple Notifications
    func test_it_continuously_updates_the_state_when_multiple_events_happen() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        let expectedLastFrameEnd = CGRect(x: 888, y: 555, width: 121_411, height: 971_471)

        // Act
        notificationCenter.postKeyboardWillHideNotification(frameEnd: .zero)
        notificationCenter.postKeyboardWillShowNotification(frameEnd: CGRect(x: 1, y: 2, width: 3, height: 4))
        notificationCenter.postKeyboardWillHideNotification(frameEnd: .zero)
        notificationCenter.postKeyboardWillShowNotification(frameEnd: expectedLastFrameEnd)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: true, frameEnd: expectedLastFrameEnd))
    }

    func test_it_updates_the_state_to_zero_frame_end_when_the_notification_has_no_frame_end() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        // Act
        notificationCenter.postKeyboardWillShowNotification(frameEnd: nil)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: true, frameEnd: .zero))
    }
}

private extension NotificationCenter {
    func postKeyboardWillShowNotification(frameEnd: CGRect? = nil) {
        let userInfo: [AnyHashable: Any]? = {
            if let frameEnd = frameEnd {
                return [UIResponder.keyboardFrameEndUserInfoKey: frameEnd]
            } else {
                return nil
            }
        }()

        post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: userInfo)
    }

    func postKeyboardWillHideNotification(frameEnd: CGRect) {
        let userInfo = [UIResponder.keyboardFrameEndUserInfoKey: frameEnd]
        post(name: UIResponder.keyboardWillHideNotification, object: nil, userInfo: userInfo)
    }
}
