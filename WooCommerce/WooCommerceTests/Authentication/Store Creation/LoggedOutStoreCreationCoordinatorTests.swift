import TestKit
import XCTest
@testable import WooCommerce

final class LoggedOutStoreCreationCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_start_shows_AccountCreationFormHostingController() throws {
        // Given
        let coordinator = LoggedOutStoreCreationCoordinator(source: .prologue, navigationController: navigationController)
        XCTAssertNil(navigationController.topViewController)

        // When
        coordinator.start()

        // Then
        assertThat(navigationController.topViewController, isAnInstanceOf: AccountCreationEmailFormHostingController.self)
    }
}
