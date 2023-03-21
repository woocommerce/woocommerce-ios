import TestKit
import XCTest
@testable import WooCommerce

@MainActor
final class StoreOnboardingCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
    }

    override func tearDown() {
        navigationController = nil
        super.tearDown()
    }

    func test_starting_with_customDomains_task_presents_DomainSettingsHostingController() throws {
        // Given
        let coordinator = StoreOnboardingCoordinator(navigationController: navigationController, site: .fake())

        // When
        coordinator.start(task: .init(isComplete: true, type: .customizeDomains))
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        let presentedNavigationController = try XCTUnwrap(coordinator.navigationController.presentedViewController as? WooNavigationController)
        assertThat(presentedNavigationController.topViewController, isAnInstanceOf: DomainSettingsHostingController.self)
    }

    func test_isRelatedToOnboardingTask_returns_true_for_relevant_types() {
        let url = URL(string: "https://example.com/")!
        let domain = DomainSettingsHostingController(viewModel: .init(siteID: 0),
                                                     addDomain: { _, _ in },
                                                     onClose: {})
        XCTAssertTrue(StoreOnboardingCoordinator.isRelatedToOnboardingTask(domain))

        let launch = StoreOnboardingLaunchStoreHostingController(viewModel: .init(siteURL: url,
                                                                                  siteID: 9,
                                                                                  onLaunch: {}))
        XCTAssertTrue(StoreOnboardingCoordinator.isRelatedToOnboardingTask(launch))

        let launched = StoreOnboardingStoreLaunchedHostingController(siteURL: url, onContinue: {})
        XCTAssertTrue(StoreOnboardingCoordinator.isRelatedToOnboardingTask(launched))

        let payments = StoreOnboardingPaymentsSetupHostingController(task: .wcPay, onContinue: {}, onDismiss: {})
        XCTAssertTrue(StoreOnboardingCoordinator.isRelatedToOnboardingTask(payments))
    }
}
