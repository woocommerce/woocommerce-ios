import XCTest
@testable import WooCommerce
import TestKit

final class RemoveAppleIDAccessCoordinatorTests: XCTestCase {
    private var sourceViewController: UIViewController!
    private var window: UIWindow?

    override func setUp() {
        super.setUp()
        sourceViewController = .init()

        self.window = {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.makeKeyAndVisible()
            window.rootViewController = sourceViewController
            return window
        }()
    }

    override func tearDown() {
        sourceViewController = nil

        // Resets `UIWindow` and its view hierarchy so that it can be deallocated cleanly.
        window?.resignKey()
        window?.rootViewController = nil

        super.tearDown()
    }

    func test_alert_is_presented_when_starting_coordinator() throws {
        // Given
        let coordinator = RemoveAppleIDAccessCoordinator(sourceViewController: sourceViewController) {
            return .success(())
        } onRemoveSuccess: {}

        // When
        coordinator.start()

        // Then
        assertThat(sourceViewController.presentedViewController, isAnInstanceOf: UIAlertController.self)
        let alertController = try XCTUnwrap(sourceViewController.presentedViewController as? UIAlertController)
        XCTAssertEqual(alertController.actions.count, 2)
    }
}
