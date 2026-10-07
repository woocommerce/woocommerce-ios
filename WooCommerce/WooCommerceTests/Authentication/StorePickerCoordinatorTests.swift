import TestKit
import WordPressAuthenticator
import XCTest
import Yosemite
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

    @MainActor
    func test_requirement_failure_when_picker_configuration_changes_then_only_login_and_recovery_track_after_presentation() throws {
        for (configuration, expectedDetection) in [(StorePickerConfiguration.login, true), (.listStores, true),
                                                   (.standard, false), (.switchingStores, false)] {
            // Given
            let site = Site.fake().copy(siteID: 123, isJetpackConnected: true, isWooCommerceActive: true)
            let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
            let failure = UnexpectedStoreResponseError(kind: .unacceptableStatusCode, statusCode: 503)
            var requestedDetection: Bool?
            var completeRequirementCheck: (() -> Void)?
            stores.whenReceivingAction(ofType: SettingAction.self) { action in
                if case let .retrieveSiteAPI(_, enabled, completion) = action {
                    requestedDetection = enabled
                    completeRequirementCheck = { completion(.failure(failure)) }
                }
            }
            let provider = MockAnalyticsProvider()
            var presentedModal: UIViewController?
            var presentationCompletion: (() -> Void)?
            let picker = StorePickerViewController(
                configuration: configuration,
                stores: stores,
                analytics: WooAnalytics(analyticsProvider: provider),
                errorPresenter: { _, modal, completion in
                    presentedModal = modal
                    presentationCompletion = completion
                }
            )

            // When
            picker.loadViewIfNeeded()
            picker.selectSite(site)
            waitUntil { completeRequirementCheck != nil }

            // Then: detection follows login scope, and no event precedes the failure UI.
            let event = WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue
            XCTAssertEqual(requestedDetection, expectedDetection)
            XCTAssertFalse(provider.receivedEvents.contains(event))
            try XCTUnwrap(completeRequirementCheck)()
            waitUntil { presentationCompletion != nil }
            XCTAssertTrue(presentedModal is StorePickerErrorHostingController)
            XCTAssertFalse(provider.receivedEvents.contains(event))
            try XCTUnwrap(presentationCompletion)()
            XCTAssertEqual(provider.receivedEvents.filter { $0 == event }.count, expectedDetection ? 1 : 0)
            if expectedDetection {
                XCTAssertEqual(provider.properties(for: event)?["step"] as? String, "woo_plugin_check")
                XCTAssertEqual(provider.properties(for: event)?["login_flow"] as? String, "store_picker")
                XCTAssertEqual(provider.properties(for: event)?["failure_kind"] as? String, "unacceptable_status_code")
            }
        }
    }
}
