import TestKit
import WordPressAuthenticator
import XCTest
import Yosemite
import YosemiteTestHelpers
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
    func test_requirement_failure_when_picker_configuration_changes_then_login_and_listStores_track_after_presentation() throws {
        for (configuration, expectedDetection) in [(StorePickerConfiguration.login, true), (.listStores, true),
                                                   (.standard, false), (.switchingStores, false)] {
            // Given
            let site = Site.fake().copy(siteID: 123, url: "https://first.example.test", isJetpackConnected: true, isWooCommerceActive: true)
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

            // Then: login and connected-store pickers detect failures, and no event precedes the failure UI.
            let event = WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue
            XCTAssertEqual(requestedDetection, expectedDetection)
            XCTAssertFalse(provider.receivedEvents.contains(event))
            try XCTUnwrap(completeRequirementCheck)()
            waitUntil { presentationCompletion != nil }
            XCTAssertEqual(presentedModal is UIAlertController, expectedDetection)
            if !expectedDetection { XCTAssertTrue(presentedModal is StorePickerErrorHostingController) }
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
    @MainActor
    func test_plugin_retry_when_successful_then_rechecks_same_store_and_later_role_failure_does_not_change_result() throws {
        for configuration in [StorePickerConfiguration.login, .listStores] {
            try assertPluginRetry(configuration: configuration)
        }
    }

    @MainActor
    private func assertPluginRetry(configuration: StorePickerConfiguration) throws {
        // Given
        let fixture = makeRecoveryFixture(configuration: configuration)
        fixture.picker.selectSite(fixture.site)
        waitUntil { fixture.completeRequirements != nil }
        fixture.completeRequirements?(.failure(fixture.failure))
        waitUntil { fixture.alert != nil }
        fixture.presentationCompletion?()

        // When
        fixture.picker.unexpectedResponsePresenter.select(.retry)
        fixture.picker.unexpectedResponsePresenter.select(.retry)
        waitUntil { fixture.requirementSiteIDs.count == 2 }
        fixture.completeRequirements?(.success(fixture.validAPI))
        waitUntil { fixture.continueButton?.isEnabled == true }
        fixture.continueButton?.sendActions(for: .touchUpInside)
        fixture.completeRole?(.failure(fixture.failure))
        waitUntil { fixture.alert?.title == "Unable to log in" && fixture.alertCount == 2 }
        fixture.presentationCompletion?()

        // Then
        let event = WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue
        XCTAssertEqual(fixture.requirementSiteIDs, [fixture.site.siteID, fixture.site.siteID])
        XCTAssertEqual(fixture.provider.receivedEvents.filter { $0 == event }.count, 1)
        XCTAssertEqual(fixture.provider.properties(for: event)?["step"] as? String, "woo_plugin_check")
        XCTAssertEqual(fixture.provider.properties(for: event)?["result"] as? String, "success")
        XCTAssertEqual(fixture.provider.receivedProperties.last?["step"] as? String, "user_role_check")
    }

    @MainActor
    func test_role_retry_when_successful_then_rechecks_same_store_without_repeating_requirements() {
        for configuration in [StorePickerConfiguration.login, .listStores] {
            assertRoleRetry(configuration: configuration)
        }
    }

    @MainActor
    private func assertRoleRetry(configuration: StorePickerConfiguration) {
        // Given
        let fixture = makeRecoveryFixture(configuration: configuration)
        fixture.picker.selectSite(fixture.site)
        waitUntil { fixture.completeRequirements != nil }
        fixture.completeRequirements?(.success(fixture.validAPI))
        waitUntil { fixture.continueButton?.isEnabled == true }
        fixture.continueButton?.sendActions(for: .touchUpInside)
        fixture.completeRole?(.failure(fixture.failure))
        waitUntil { fixture.alert != nil }

        // When
        fixture.picker.unexpectedResponsePresenter.select(.retry)
        fixture.picker.unexpectedResponsePresenter.select(.retry)
        fixture.completeRole?(.success(.fake().copy(roles: ["administrator"])))

        // Then
        XCTAssertEqual(fixture.requirementSiteIDs, [fixture.site.siteID])
        XCTAssertEqual(fixture.roleSiteIDs, [fixture.site.siteID, fixture.site.siteID])
        XCTAssertEqual(fixture.selectionSpy.selectedStoreIDs, [fixture.site.siteID])
        let event = WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue
        XCTAssertEqual(fixture.provider.receivedEvents.filter { $0 == event }.count, 1)
        XCTAssertEqual(fixture.provider.properties(for: event)?["step"] as? String, "user_role_check")
        XCTAssertEqual(fixture.provider.properties(for: event)?["result"] as? String, "success")
    }

    @MainActor
    func test_selection_change_when_plugin_retry_is_pending_then_ignores_old_result_and_preserves_new_selection() {
        // Given
        let fixture = PickerRecoveryFixture()
        fixture.picker.selectSite(fixture.site)
        waitUntil { fixture.completeRequirements != nil }
        fixture.completeRequirements?(.failure(fixture.failure))
        waitUntil { fixture.alert != nil }
        fixture.picker.unexpectedResponsePresenter.select(.retry)
        waitUntil { fixture.requirementSiteIDs.count == 2 }
        let staleCompletion = fixture.completeRequirements
        let otherSite = fixture.site.copy(siteID: 456)

        // When
        fixture.picker.selectSite(otherSite)
        waitUntil { fixture.requirementSiteIDs.count == 3 }
        staleCompletion?(.success(fixture.validAPI))
        fixture.completeRequirements?(.success(fixture.validAPI))
        waitUntil { fixture.continueButton?.isEnabled == true }
        fixture.continueButton?.sendActions(for: .touchUpInside)

        // Then
        XCTAssertEqual(fixture.roleSiteIDs, [otherSite.siteID])
        XCTAssertFalse(fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
    }

    @MainActor
    func test_cancellation_when_role_retry_is_pending_then_ignores_old_result_without_switching_store() {
        // Given
        let fixture = PickerRecoveryFixture()
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.loadViewIfNeeded()
        navigation.view.layoutIfNeeded()
        navigation.pushViewController(fixture.picker, animated: false)
        fixture.picker.selectSite(fixture.site)
        waitUntil { fixture.completeRequirements != nil }
        fixture.completeRequirements?(.success(fixture.validAPI))
        waitUntil { fixture.continueButton?.isEnabled == true }
        fixture.continueButton?.sendActions(for: .touchUpInside)
        fixture.completeRole?(.failure(fixture.failure))
        waitUntil { fixture.alert != nil }
        fixture.picker.unexpectedResponsePresenter.select(.retry)
        let staleCompletion = fixture.completeRole

        // When
        navigation.popViewController(animated: false)
        staleCompletion?(.success(.fake().copy(roles: ["administrator"])))

        // Then
        XCTAssertTrue(fixture.selectionSpy.selectedStoreIDs.isEmpty)
        XCTAssertFalse(fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
    }

    @MainActor
    func test_dismiss_when_role_check_fails_then_retains_selection_and_allows_continue_without_rechecking_requirements() {
        for configuration in [StorePickerConfiguration.login, .listStores] {
            assertRoleDismiss(configuration: configuration)
        }
    }

    @MainActor
    private func assertRoleDismiss(configuration: StorePickerConfiguration) {
        // Given
        let fixture = makeRecoveryFixture(configuration: configuration)
        fixture.picker.selectSite(fixture.site)
        waitUntil { fixture.completeRequirements != nil }
        fixture.completeRequirements?(.success(fixture.validAPI))
        waitUntil { fixture.continueButton?.isEnabled == true }
        fixture.continueButton?.sendActions(for: .touchUpInside)
        fixture.completeRole?(.failure(fixture.failure))
        waitUntil { fixture.alert != nil }

        // When
        fixture.picker.unexpectedResponsePresenter.select(.dismiss)
        fixture.continueButton?.sendActions(for: .touchUpInside)
        fixture.completeRole?(.success(.fake().copy(roles: ["administrator"])))

        // Then
        XCTAssertEqual(fixture.roleSiteIDs, [fixture.site.siteID, fixture.site.siteID])
        XCTAssertEqual(fixture.requirementSiteIDs, [fixture.site.siteID])
        XCTAssertEqual(fixture.selectionSpy.selectedStoreIDs, [fixture.site.siteID])
        XCTAssertFalse(fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
    }

    @MainActor
    func test_dismiss_or_support_when_requirements_fail_then_preserves_session_and_allows_reselection() {
        for configuration in [StorePickerConfiguration.login, .listStores] {
            for action in [LoginUnexpectedResponseFailure.Action.dismiss, .contactSupport] {
                // Given
                let fixture = makeRecoveryFixture(configuration: configuration)
                let navigation = UINavigationController(rootViewController: fixture.picker)
                navigation.loadViewIfNeeded()
                fixture.picker.selectSite(fixture.site)
                waitUntil { fixture.completeRequirements != nil }
                fixture.completeRequirements?(.failure(fixture.failure))
                waitUntil { fixture.alert != nil }

                // When
                fixture.picker.unexpectedResponsePresenter.select(action)

                // Then
                XCTAssertTrue(fixture.stores.isAuthenticated)
                XCTAssertTrue(navigation.viewControllers.contains(fixture.picker))
                XCTAssertEqual(navigation.topViewController is SupportChatHostingController, action == .contactSupport)
                if let host = navigation.topViewController as? SupportChatHostingController {
                    XCTAssertEqual(host.rootView.viewModel.supportSiteAddress, fixture.site.url)
                }
                XCTAssertFalse(fixture.continueButton?.isEnabled ?? true)
                XCTAssertFalse(fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))

                // When: return from support and select the same store again.
                navigation.popToViewController(fixture.picker, animated: false)
                fixture.picker.selectSite(fixture.site)
                waitUntil { fixture.requirementSiteIDs.count == 2 }
                fixture.completeRequirements?(.success(fixture.validAPI))
                waitUntil { fixture.continueButton?.isEnabled == true }
                fixture.continueButton?.sendActions(for: .touchUpInside)

                // Then
                XCTAssertEqual(fixture.roleSiteIDs, [fixture.site.siteID])
                XCTAssertEqual(fixture.requirementSiteIDs, [fixture.site.siteID, fixture.site.siteID])
            }
        }
    }

    @MainActor
    func test_retry_when_plugin_fault_persists_then_reports_failure_and_shows_next_alert_once() {
        // Given
        let fixture = PickerRecoveryFixture()
        fixture.picker.selectSite(fixture.site)
        waitUntil { fixture.completeRequirements != nil }
        fixture.completeRequirements?(.failure(fixture.failure))
        waitUntil { fixture.alert != nil }
        fixture.presentationCompletion?()

        // When
        fixture.picker.unexpectedResponsePresenter.select(.retry)
        waitUntil { fixture.requirementSiteIDs.count == 2 }
        fixture.completeRequirements?(.failure(fixture.failure))
        waitUntil { fixture.alertCount == 2 }
        fixture.presentationCompletion?()

        // Then
        let event = WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue
        XCTAssertEqual(fixture.provider.receivedEvents.filter { $0 == event }.count, 1)
        XCTAssertEqual(fixture.provider.properties(for: event)?["result"] as? String, "failure")
        XCTAssertEqual(fixture.provider.receivedEvents.filter { $0 == WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue }.count, 2)
        XCTAssertEqual(fixture.alert?.actions.map(\.title), ["Try Again", "Contact Support", "Dismiss"])
    }

    @MainActor
    private func makeRecoveryFixture(configuration: StorePickerConfiguration) -> PickerRecoveryFixture {
        let fixture = PickerRecoveryFixture(configuration: configuration)
        if configuration == .listStores {
            // Finish the initial automatic selection before testing an explicit selection.
            waitUntil { fixture.completeRequirements != nil }
            fixture.completeRequirements?(.success(fixture.validAPI))
            waitUntil { fixture.continueButton?.isEnabled == true }
            fixture.requirementSiteIDs.removeAll()
            fixture.completeRequirements = nil
        }
        return fixture
    }
}

@MainActor
private final class PickerRecoveryFixture {
    private let configuration: StorePickerConfiguration
    let site = Site.fake().copy(siteID: 123, url: "https://first.example.test", isJetpackConnected: true, isWooCommerceActive: true)
    let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
    let provider = MockAnalyticsProvider()
    let selectionSpy = MockStorePickerViewControllerDelegate()
    private let storageManager = MockStorageManager()
    let failure = UnexpectedStoreResponseError(kind: .unexpectedContent)
    var validAPI: SiteAPI { .init(siteID: site.siteID, namespaces: ["wc/v3"], applicationPasswordAvailable: true) }
    var completeRequirements: ((Result<SiteAPI, Error>) -> Void)?
    var completeRole: ((Result<User, Error>) -> Void)?
    var requirementSiteIDs: [Int64] = []
    var roleSiteIDs: [Int64] = []
    var alert: UIAlertController?
    var presentationCompletion: (() -> Void)?
    var alertCount = 0
    lazy var picker = StorePickerViewController(configuration: configuration, stores: stores,
                                                analytics: WooAnalytics(analyticsProvider: provider),
                                                viewModel: StorePickerViewModel(configuration: configuration, stores: stores, storageManager: storageManager),
                                                errorPresenter: { [weak self] _, modal, completion in
        self?.alert = modal as? UIAlertController
        self?.presentationCompletion = completion
        self?.alertCount += 1
    })
    var continueButton: UIButton? { findButton(in: picker.view) }

    init(configuration: StorePickerConfiguration = .login) {
        self.configuration = configuration
        let sites = [site, site.copy(siteID: 456, url: "https://second.example.test")]
        storageManager.performAndSave({ storage in
            for site in sites { storage.insertNewObject(ofType: StorageSite.self).update(with: site) }
        }, completion: nil, on: .main)
        stores.whenReceivingAction(ofType: SettingAction.self) { [weak self] action in
            if case let .retrieveSiteAPI(siteID, enabled, completion) = action {
                XCTAssertTrue(enabled)
                self?.requirementSiteIDs.append(siteID)
                self?.completeRequirements = completion
            }
        }
        stores.whenReceivingAction(ofType: UserAction.self) { [weak self] action in
            if case let .retrieveUser(siteID, enabled, completion) = action {
                XCTAssertTrue(enabled)
                self?.roleSiteIDs.append(siteID)
                self?.completeRole = completion
            }
        }
        picker.delegate = selectionSpy
        picker.loadViewIfNeeded()
    }

    private func findButton(in view: UIView) -> UIButton? {
        if view.accessibilityIdentifier == "login-epilogue-continue-button" { return view as? UIButton }
        return view.subviews.compactMap { findButton(in: $0) }.first
    }
}
