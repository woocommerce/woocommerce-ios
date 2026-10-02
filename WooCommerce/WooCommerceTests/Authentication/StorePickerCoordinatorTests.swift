import TestKit
import WordPressShared
@testable import WordPressAuthenticator
import XCTest
@testable import WooCommerce

final class StorePickerCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController

        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_standard_configuration_presents_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .standard)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        XCTAssertNil(navigationController.topViewController)

        let storePickerNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_switchingStores_configuration_presents_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .switchingStores)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        XCTAssertNil(navigationController.topViewController)

        let storePickerNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_login_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .login)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }

    func test_listStores_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .listStores)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }

    func test_didSelectStore_when_logging_in_then_reports_success() {
        // Given a login that has reached the point of choosing a store
        var events: [AnalyticsEvent] = []
        let tracker = AuthenticatorAnalyticsTracker(enabled: true, track: { events.append($0) })
        tracker.set(flow: .epilogue)
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .login,
                                                 switchStoreUseCase: MockSwitchStoreUseCase(),
                                                 tracker: tracker)

        // When
        coordinator.didSelectStore(with: 123) {}

        // Then the login ends where the store does, matching where Android reports it
        waitUntil {
            events.filter { $0.properties["step"] == "success" }.count == 1
        }
        XCTAssertEqual(events.first(where: { $0.properties["step"] == "success" })?.properties["flow"], "epilogue")
    }

    func test_didSelectStore_when_switching_stores_then_does_not_report_success() {
        // Given a merchant already signed in, changing store
        var events: [AnalyticsEvent] = []
        let tracker = AuthenticatorAnalyticsTracker(enabled: true, track: { events.append($0) })
        let coordinator = StorePickerCoordinator(navigationController,
                                                 config: .switchingStores,
                                                 switchStoreUseCase: MockSwitchStoreUseCase(),
                                                 tracker: tracker)

        // When
        let completed = expectation(description: "store switched")
        coordinator.didSelectStore(with: 123) { completed.fulfill() }
        wait(for: [completed], timeout: Constants.expectationTimeout)

        // Then no login is happening, so no login step is invented
        XCTAssertFalse(events.contains { $0.properties["step"] == "success" })
    }
}
