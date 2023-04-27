import Codegen
import XCTest
import Yosemite

import protocol Storage.StorageType
import protocol Storage.StorageManagerType

@testable import WooCommerce

final class SettingsViewModelTests: XCTestCase {

    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType!

    /// Mock Stores
    ///
    private var stores: MockStoresManager!

    private var defaults: UserDefaults!

    private var sessionManager: SessionManager!

    private var appleIDCredentialChecker: AppleIDCredentialCheckerProtocol!

    private var analyticsProvider: MockAnalyticsProvider!

    private var analytics: WooAnalytics!

    override func setUpWithError() throws {
        super.setUp()
        storageManager = MockStorageManager()
        sessionManager = .makeForTesting(authenticated: true)
        stores = MockStoresManager(sessionManager: sessionManager)
        let uuid = UUID().uuidString
        defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: false)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        appleIDCredentialChecker = nil
        storageManager = nil
        stores = nil
        sessionManager = nil
        defaults = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_sections_is_not_empty_after_view_did_load() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager, appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.count > 0)
    }

    func test_sections_contain_install_jetpack_row_when_default_site_is_jcp() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: false, isJetpackConnected: true)
        sessionManager.defaultSite = site
        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: storageManager,
            appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })
    }

    func test_sections_do_not_contain_install_jetpack_row_when_default_site_is_not_jcp() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: true, isJetpackConnected: true)
        sessionManager.defaultSite = site
        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: storageManager,
            appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })
    }

    func test_refresh_view_content_method_is_invoked_after_view_did_load() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager, appleIDCredentialChecker: appleIDCredentialChecker)
        let presenter = MockSettingsPresenter()
        viewModel.presenter = presenter

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(presenter.refreshViewContentCalled)
    }

    func test_refresh_view_content_method_is_invoked_after_dismissing_store_picker() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager, appleIDCredentialChecker: appleIDCredentialChecker)
        let presenter = MockSettingsPresenter()
        viewModel.presenter = presenter

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(presenter.refreshViewContentCalled)

        // Reset
        presenter.refreshViewContentCalled = false

        // When
        viewModel.onStorePickerDismiss()

        // Then
        XCTAssertTrue(presenter.refreshViewContentCalled)
    }

    func test_onJetpackInstallDismiss_updates_sections_correctly() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: false, isJetpackConnected: true)
        sessionManager.defaultSite = site
        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: storageManager,
            appleIDCredentialChecker: appleIDCredentialChecker)

        viewModel.onViewDidLoad()
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })

        // When
        let updatedSite = site.copy(isJetpackThePluginInstalled: true, isJetpackConnected: false)
        sessionManager.defaultSite = updatedSite
        viewModel.onJetpackInstallDismiss()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })
    }

    // MARK: - `closeAccount` row visibility

    func test_closeAccount_section_is_shown_when_user_apple_id_exists() {
        // Given
        let appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: true)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.closeAccount) })
    }

    func test_closeAccount_section_is_hidden_when_apple_id_does_not_exist_and_store_creation_features_disabled() {
        // Given
        let appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: false)
        let featureFlagService = MockFeatureFlagService(isStoreCreationMVPEnabled: false, isStoreCreationM2Enabled: false)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.closeAccount) })
    }

    func test_closeAccount_section_is_hidden_when_authenticated_without_wpcom() {
        // Given
        let appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: false)
        let featureFlagService = MockFeatureFlagService(isStoreCreationMVPEnabled: true, isStoreCreationM2Enabled: true)
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: false)
        let stores = DefaultStoresManager(sessionManager: sessionManager)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.closeAccount) })
    }

    func test_domain_is_hidden_when_domainSettings_feature_is_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDomainSettingsEnabled: false)
        stores.updateDefaultStore(.fake().copy(isWordPressComStore: true))
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.domain) })
    }

    func test_domain_is_hidden_when_domainSettings_feature_is_enabled_and_site_is_not_wpcom() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDomainSettingsEnabled: true)
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: false)
        sessionManager.defaultRoles = [.administrator]
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.domain) })
    }

    func test_domain_is_not_shown_when_domainSettings_feature_is_enabled_and_site_is_wpcom_for_shop_manager_role() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDomainSettingsEnabled: true)
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: true)
        sessionManager.defaultRoles = [.shopManager]
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.domain) })
    }

    func test_domain_is_shown_when_domainSettings_feature_is_enabled_and_site_is_wpcom_for_admin_role() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDomainSettingsEnabled: true)
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.domain) })
    }

    // MARK: - `Store Setup List` row

    func test_store_setup_list_row_is_shown_when_there_are_pending_onboarding_tasks() {
        // Given
        defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] = false
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker,
                                          defaults: defaults)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.storeSetupList) })
    }

    func test_store_setup_list_row_is_hidden_when_there_are_no_pending_onboarding_tasks() {
        // Given
        defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] = true
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker,
                                          defaults: defaults)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.storeSetupList) })
    }

    // MARK: - `isStoreSetupSettingSwitchOn`

    func test_isStoreSetupSettingSwitchOn_is_true_when_shouldHideStoreOnboardingTaskList_is_false() {
        // Given
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker,
                                          defaults: defaults)

        // When
        defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] = false

        // Then
        XCTAssertTrue(viewModel.isStoreSetupSettingSwitchOn)
    }

    func test_isStoreSetupSettingSwitchOn_is_false_when_shouldHideStoreOnboardingTaskList_is_true() {
        // Given
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker,
                                          defaults: defaults)

        // When
        defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] = true

        // Then
        XCTAssertFalse(viewModel.isStoreSetupSettingSwitchOn)
    }

    // MARK: - `updateStoreSetupListVisibility` method

    func test_updateStoreSetupListVisibility_updates_user_defaults() async {
        // Given
        defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] = nil
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker,
                                          defaults: defaults)

        // When
        await viewModel.updateStoreSetupListVisibility(false)

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] as? Bool))

        // When
        await viewModel.updateStoreSetupListVisibility(true)

        // Then
        XCTAssertFalse(try XCTUnwrap(defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] as? Bool))
    }

    func test_updateStoreSetupListVisibility_tracks_hide_list_event_upon_hiding_list() async throws {
        // Given
        sessionManager.defaultSite = Site.fake()
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: true, type: .storeDetails),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker,
                                          defaults: defaults,
                                          analytics: analytics)

        stores.whenReceivingAction(ofType: StoreOnboardingTasksAction.self) { action in
            guard case let .loadOnboardingTasks(_, completion) = action else {
                return XCTFail()
            }
            completion(.success(tasks))
        }

        // When
        await viewModel.updateStoreSetupListVisibility(false)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "store_onboarding_hide_list"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["source"] as? String, "settings")
        XCTAssertEqual(eventProperties["pending_tasks"] as? String, "add_domain,launch_site,payments,products")
    }

    func test_updateStoreSetupListVisibility_does_not_track_hide_list_event_upon_showing_list() async throws {
        // Given
        sessionManager.defaultSite = Site.fake()
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: true, type: .storeDetails),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker,
                                          defaults: defaults,
                                          analytics: analytics)

        stores.whenReceivingAction(ofType: StoreOnboardingTasksAction.self) { action in
            guard case let .loadOnboardingTasks(_, completion) = action else {
                return XCTFail()
            }
            completion(.success(tasks))
        }

        // When
        await viewModel.updateStoreSetupListVisibility(true)

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(where: { $0 == "store_onboarding_hide_list"}))
    }
}

private final class MockSettingsPresenter: SettingsViewPresenter {

    var refreshViewContentCalled = false

    func refreshViewContent() {
        refreshViewContentCalled = true
    }
}
