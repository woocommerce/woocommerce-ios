import XCTest

@testable import WooCommerce

final class KeyboardFrameObserverTests: XCTestCase {

    // If the keyboard frame is the same from multiple notification posts, it should only
    // notify the subscriber once.
    func testObservingKeyboardFrameChangesWithTheSameFrame() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        let expectedFrame = CGRect(origin: .zero, size: CGSize(width: 10, height: 18))
        let expectedFrames: [CGRect] = [expectedFrame, .zero]

        var actualFrames = [CGRect]()

        var keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
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

    func testObservingKeyboardFrameChangesWithDifferentFrames() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        let expectedFrameForShow = CGRect(origin: .zero, size: CGSize(width: 10, height: 18))
        let expectedFrameForHide = CGRect.zero
        let expectedFrames: [CGRect] = [expectedFrameForShow, expectedFrameForHide]

        var actualFrames = [CGRect]()

        var keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
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

    func testObservingKeyboardFrameChangesWithNonKeyboardNotification() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        var keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
            expectationForKeyboardFrame.fulfill()
        }
        keyboardFrameObserver.startObservingKeyboardFrame()

        notificationCenter.postNonKeyboardNotification()
        notificationCenter.postNonKeyboardNotification()

        // The expectation should not be fulfilled.
        expectationForKeyboardFrame.isInverted = true
        waitForExpectations(timeout: 0.1)
    }

    func testObservingKeyboardFrameChangesWithoutKeyboardUserInfo() {
        let notificationCenter = NotificationCenter()

        let expectationForKeyboardFrame = expectation(description: "Wait for keyboard frame updates")

        var keyboardFrameObserver = KeyboardFrameObserver(notificationCenter: notificationCenter) { (keyboardFrame: CGRect) in
            expectationForKeyboardFrame.fulfill()
        }
        keyboardFrameObserver.startObservingKeyboardFrame()

        notificationCenter.postKeyboardFrameNotificationWithoutUserInfo()
        notificationCenter.postKeyboardFrameNotificationWithoutUserInfo()

        // The expectation should not be fulfilled.
        expectationForKeyboardFrame.isInverted = true
        waitForExpectations(timeout: 0.1)
    }
    
    func testItCanSendInitialEvents() {
        // Arrange
        let expectedKeyboardState = KeyboardState(
            isVisible: true,
            frameEnd: CGRect(x: 2_100, y: 3_123, width: 9_981_123, height: 1_514)
        )
        let keyboardStateProvider = MockKeyboardStateProvider(state: expectedKeyboardState)

        var actualKeyboardFrame: CGRect = .zero
        var keyboardFrameObserver = KeyboardFrameObserver(keyboardStateProvider: keyboardStateProvider) { frame in
            actualKeyboardFrame = frame
        }

        // Act
        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)

        // Assert
        XCTAssertEqual(actualKeyboardFrame, expectedKeyboardState.frameEnd)
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
