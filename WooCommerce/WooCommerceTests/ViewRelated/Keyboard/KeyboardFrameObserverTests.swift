import XCTest

@testable import WooCommerce

final class KeyboardFrameObserverTests: XCTestCase {

    // If the keyboard frame is the same from multiple notification posts, it should only
    // notify the subscriber once.
    func test_observing_keyboard_frame_changes_with_the_same_frame() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        let expectedFrame = CGRect(origin: .zero, size: CGSize(width: 10, height: 18))
        let expectedFrames: [CGRect] = [expectedFrame, .zero]

        var actualFrames = [CGRect]()

        let keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
            actualFrames.append(keyboardFrame)
            if actualFrames.count >= expectedFrames.count {
                XCTAssertEqual(actualFrames, expectedFrames)
                expectationForKeyboardFrame.fulfill()
            }
        }
        keyboardFrameObserver.startObservingKeyboardFrame()

        notificationCenter.postKeyboardWillShowNotification(keyboardFrame: expectedFrame)

        notificationCenter.postKeyboardWillShowNotification(keyboardFrame: expectedFrame)
        notificationCenter.postKeyboardWillHideNotification(keyboardFrame: expectedFrame)

        // The expectation should only be fulfilled once.
        expectationForKeyboardFrame.expectedFulfillmentCount = 1
        expectationForKeyboardFrame.assertForOverFulfill = true
        waitForExpectations(timeout: 0.1)
    }

    func test_observing_keyboard_frame_changes_with_different_frames() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        let expectedFrameForShow = CGRect(origin: .zero, size: CGSize(width: 10, height: 18))
        let expectedFrameForHide = CGRect.zero
        let expectedFrames: [CGRect] = [expectedFrameForShow, expectedFrameForHide]

        var actualFrames = [CGRect]()

        let keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
            actualFrames.append(keyboardFrame)
            if actualFrames.count >= expectedFrames.count {
                XCTAssertEqual(actualFrames, expectedFrames)
                expectationForKeyboardFrame.fulfill()
            }
        }
        keyboardFrameObserver.startObservingKeyboardFrame()

        notificationCenter.postKeyboardWillShowNotification(keyboardFrame: expectedFrameForShow)
        notificationCenter.postKeyboardWillHideNotification(keyboardFrame: expectedFrameForHide)

        // The expectation should only be fulfilled once.
        expectationForKeyboardFrame.expectedFulfillmentCount = 1
        expectationForKeyboardFrame.assertForOverFulfill = true
        waitForExpectations(timeout: 0.1)
    }

    func test_observing_keyboard_frame_changes_with_non_keyboard_notification() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        let keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
            expectationForKeyboardFrame.fulfill()
        }
        keyboardFrameObserver.startObservingKeyboardFrame()

        notificationCenter.postNonKeyboardNotification()
        notificationCenter.postNonKeyboardNotification()

        // The expectation should not be fulfilled.
        expectationForKeyboardFrame.isInverted = true
        waitForExpectations(timeout: 0.1)
    }

    func test_observing_keyboard_frame_changes_without_keyboard_user_info() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        let keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
            expectationForKeyboardFrame.fulfill()
        }
        keyboardFrameObserver.startObservingKeyboardFrame()

        notificationCenter.postKeyboardFrameNotificationWithoutUserInfo()
        notificationCenter.postKeyboardFrameNotificationWithoutUserInfo()

        // The expectation should not be fulfilled.
        expectationForKeyboardFrame.isInverted = true
        waitForExpectations(timeout: 0.1)
    }

    func test_it_will_not_emit_new_events_when_it_is_deallocated() {
        // Arrange
        let notificationCenter = NotificationCenter()

        var eventsLogged = 0
        var keyboardFrameObserver: KeyboardFrameObserver? = KeyboardFrameObserver(notificationCenter: notificationCenter) { _ in
            eventsLogged += 1
        }

        keyboardFrameObserver?.startObservingKeyboardFrame()

        // These should be logged
        notificationCenter.postKeyboardWillShowNotification(keyboardFrame: CGRect(x: 1, y: 1, width: 1, height: 1))
        notificationCenter.postKeyboardWillShowNotification(keyboardFrame: CGRect(x: 2, y: 2, width: 2, height: 2))

        // Act
        keyboardFrameObserver = nil

        // This should not be logged anymore
        notificationCenter.postKeyboardWillShowNotification(keyboardFrame: CGRect(x: 3, y: 3, width: 3, height: 3))

        // Assert
        XCTAssertEqual(eventsLogged, 2)
    }

    func test_it_can_send_initial_events() {
        // Arrange
        let expectedKeyboardState = KeyboardState(
            isVisible: true,
            frameEnd: CGRect(x: 2_100, y: 3_123, width: 9_981_123, height: 1_514)
        )
        let keyboardStateProvider = MockKeyboardStateProvider(state: expectedKeyboardState)

        var actualKeyboardFrame: CGRect = .zero
        let keyboardFrameObserver = KeyboardFrameObserver(keyboardStateProvider: keyboardStateProvider) { frame in
            actualKeyboardFrame = frame
        }

        // Act
        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)

        // Assert
        XCTAssertEqual(actualKeyboardFrame, expectedKeyboardState.frameEnd)
    }

    /// iOS can send a non-zero frame even if the keyboard is visible. KeyboardStateFrameObserver
    /// makes sure that a zero frame is sent if this happens.
    ///
    /// See the `KeyboardState.frameEnd` for more info about this behavior.
    ///
    func test_it_will_send_a_zero_frame_if_the_current_keyboard_is_not_visible() {
        // Arrange
        // Emit a non-zero frame
        let emittedKeyboardState = KeyboardState(
            isVisible: false,
            frameEnd: CGRect(x: 2_100, y: 3_123, width: 9_981_123, height: 1_514)
        )
        let keyboardStateProvider = MockKeyboardStateProvider(state: emittedKeyboardState)

        var actualKeyboardFrame: CGRect? = nil
        let keyboardFrameObserver = KeyboardFrameObserver(keyboardStateProvider: keyboardStateProvider) { frame in
            actualKeyboardFrame = frame
        }

        // Act
        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)

        // Assert
        XCTAssertEqual(actualKeyboardFrame, .zero)
    }
}

private extension NotificationCenter {
    func postKeyboardWillShowNotification(keyboardFrame: CGRect) {
        post(name: UIResponder.keyboardWillShowNotification,
             object: nil,
             userInfo: [UIResponder.keyboardFrameEndUserInfoKey: keyboardFrame])
    }

    func postKeyboardWillHideNotification(keyboardFrame: CGRect) {
        post(name: UIResponder.keyboardWillHideNotification,
             object: nil,
             userInfo: [UIResponder.keyboardFrameEndUserInfoKey: keyboardFrame])
    }

    func postKeyboardFrameNotificationWithoutUserInfo() {
        post(name: UIResponder.keyboardWillShowNotification,
             object: nil,
             userInfo: nil)
    }

    func postNonKeyboardNotification() {
        post(name: NSNotification.Name(rawValue: UIResponder.keyboardAnimationCurveUserInfoKey),
             object: nil,
             userInfo: [UIResponder.keyboardFrameEndUserInfoKey: CGRect.zero])
    }
}

private struct MockKeyboardStateProvider: KeyboardStateProviding {
    let state: KeyboardState
}
