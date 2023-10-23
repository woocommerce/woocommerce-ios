import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class StoreCreationCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil

        analytics = nil
        analyticsProvider = nil

        super.tearDown()
    }

    func test_siteCreationFlowStarted_is_tracked_upon_start() throws {
        // Given
        let coordinator = StoreCreationCoordinator(source: .loggedOut(source: .prologue),
                                                   navigationController: navigationController,
                                                   analytics: analytics)

        // When
        coordinator.start()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("site_creation_flow_started"))
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "site_creation_flow_started"))
        let eventProperties = analyticsProvider.receivedProperties[index]
        XCTAssertEqual(eventProperties["source"] as? String, "prologue")
    }

    func test_FreeTrialSummaryHostingController_is_presented_upon_start() throws {
        // Given
        let coordinator = StoreCreationCoordinator(source: .storePicker,
                                                   navigationController: navigationController)
        waitFor { promise in
            self.navigationController.present(.init(), animated: false) {
                promise(())
            }
        }
        XCTAssertNotNil(navigationController.presentedViewController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is FreeTrialSummaryHostingController
        }
    }

    func test_FreeTrialSummaryHostingController_is_presented_when_navigationController_is_showing_another_view() throws {
        // Given
        navigationController.show(.init(), sender: nil)
        let coordinator = StoreCreationCoordinator(source: .loggedOut(source: .loginEmailError),
                                                   navigationController: navigationController)
        XCTAssertNotNil(navigationController.topViewController)
        XCTAssertNil(navigationController.presentedViewController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is FreeTrialSummaryHostingController
        }
    }
}
