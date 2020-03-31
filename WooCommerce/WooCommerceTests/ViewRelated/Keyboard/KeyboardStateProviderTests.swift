
import XCTest
import UIKit
@testable import WooCommerce

/// Tests for the concrete `KeyboardStateProvider`
///
final class KeyboardStateProviderTests: XCTestCase {
    func testItDefaultsToNotVisibleAndNoFrame() {
        let provider = KeyboardStateProvider()

        XCTAssertEqual(provider.state, KeyboardState(isVisible: false, frameEnd: .zero))
    }

    func testItUpdatesTheStateWhenTheKeyboardIsShown() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        let expectedFrameEnd = CGRect(x: 1_981, y: 9_312, width: 311, height: 981)

        // Act
        notificationCenter.postKeyboardDidShowNotification(frameEnd: expectedFrameEnd)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: true, frameEnd: expectedFrameEnd))
    }

    func testItUpdatesTheStateWhenTheKeyboardIsHidden() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        // Still using a dummy CGRect and not zero to test that KeyboardStateProvider uses the
        // frame given by the Notification
        let expectedFrameEnd = CGRect(x: 981, y: 5_135, width: 146, height: 561)

        // Act
        notificationCenter.postKeyboardDidHideNotification(frameEnd: expectedFrameEnd)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: false, frameEnd: expectedFrameEnd))
    }

    /// Test receiving multiple Notifications
    func testItContinuouslyUpdatesTheStateWhenMultipleEventsHappen() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        let expectedLastFrameEnd = CGRect(x: 888, y: 555, width: 121_411, height: 971_471)

        // Act
        notificationCenter.postKeyboardDidHideNotification(frameEnd: .zero)
        notificationCenter.postKeyboardDidShowNotification(frameEnd: CGRect(x: 1, y: 2, width: 3, height: 4))
        notificationCenter.postKeyboardDidHideNotification(frameEnd: .zero)
        notificationCenter.postKeyboardDidShowNotification(frameEnd: expectedLastFrameEnd)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: true, frameEnd: expectedLastFrameEnd))
    }

    func testItUpdatesTheStateToZeroFrameEndWhenTheNotificationHasNoFrameEnd() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let provider = KeyboardStateProvider(notificationCenter: notificationCenter)

        // Act
        notificationCenter.postKeyboardDidShowNotification(frameEnd: nil)

        // Assert
        XCTAssertEqual(provider.state, KeyboardState(isVisible: true, frameEnd: .zero))
    }
}

private extension NotificationCenter {
    func postKeyboardDidShowNotification(frameEnd: CGRect? = nil) {
        let userInfo: [AnyHashable: Any?]? = {
            if let frameEnd = frameEnd {
                return [UIResponder.keyboardFrameEndUserInfoKey: frameEnd]
            } else {
                return nil
            }
        }()

        post(name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: userInfo)
    }

    func postKeyboardDidHideNotification(frameEnd: CGRect) {
        let userInfo = [UIResponder.keyboardFrameEndUserInfoKey: frameEnd]
        post(name: UIResponder.keyboardDidHideNotification, object: nil, userInfo: userInfo)
    }
}
