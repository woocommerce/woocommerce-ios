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

    // MARK: - `removeAppleIDAccess` row visibility

    func test_removeAppleIDAccess_section_is_shown_when_user_apple_id_exists() {
        // Given
        let featureFlagService = MockFeatureFlagService(isAppleIDAccountDeletionEnabled: true)
        let appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: true)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.removeAppleIDAccess) })
    }

    func test_removeAppleIDAccess_section_is_not_shown_when_user_apple_id_does_not_exist() {
        // Given
        let featureFlagService = MockFeatureFlagService(isAppleIDAccountDeletionEnabled: true)
        let appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: false)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.removeAppleIDAccess) })
    }

    func test_removeAppleIDAccess_section_is_not_shown_when_user_apple_id_exists_but_feature_flag_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(isAppleIDAccountDeletionEnabled: false)
        let appleIDCredentialChecker = MockAppleIDCredentialChecker(hasAppleUserID: true)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService,
                                          appleIDCredentialChecker: appleIDCredentialChecker)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.removeAppleIDAccess) })
    }
}

private final class MockSettingsPresenter: SettingsViewPresenter {

    var refreshViewContentCalled = false

    func refreshViewContent() {
        refreshViewContentCalled = true
    }
}
