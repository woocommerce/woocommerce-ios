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

    private var sessionManager: SessionManager!

    private var appleIDCredentialChecker: AppleIDCredentialCheckerProtocol!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        sessionManager = .makeForTesting(authenticated: true)
        stores = MockStoresManager(sessionManager: sessionManager)
        appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: false)
    }

    override func tearDown() {
        appleIDCredentialChecker = nil
        storageManager = nil
        stores = nil
        sessionManager = nil
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
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.domain) })
    }

    func test_domain_is_shown_when_domainSettings_feature_is_enabled_and_site_is_wpcom() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDomainSettingsEnabled: true)
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: true)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.domain) })
    }

    // MARK: - `accountName` tests
    func test_accountName_is_correct_when_authenticated_without_wpcom() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: false)
        let stores = DefaultStoresManager(sessionManager: sessionManager)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertEqual(viewModel.accountName, SessionSettings.wporgCredentials.username)
    }

    func test_accountName_is_correct_when_authenticated_with_wpcom() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        let stores = DefaultStoresManager(sessionManager: sessionManager)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertEqual(viewModel.accountName, SessionSettings.wpcomCredentials.username)
    }
}

private final class MockSettingsPresenter: SettingsViewPresenter {

    var refreshViewContentCalled = false

    func refreshViewContent() {
        refreshViewContentCalled = true
    }
}
