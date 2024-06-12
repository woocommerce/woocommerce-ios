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

    private var analyticsProvider: MockAnalyticsProvider!

    private var analytics: WooAnalytics!

    override func setUpWithError() throws {
        super.setUp()
        storageManager = MockStorageManager()
        sessionManager = .makeForTesting(authenticated: true)
        stores = MockStoresManager(sessionManager: sessionManager)
        let uuid = UUID().uuidString
        defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
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
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager)

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
            storageManager: storageManager)

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
            storageManager: storageManager)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })
    }

    func test_refresh_view_content_method_is_invoked_after_view_did_load() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager)
        let presenter = MockSettingsPresenter()
        viewModel.presenter = presenter

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(presenter.refreshViewContentCalled)
    }

    func test_refresh_view_content_method_is_invoked_after_dismissing_store_picker() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager)
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
            storageManager: storageManager)

        viewModel.onViewDidLoad()
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })

        // When
        let updatedSite = site.copy(isJetpackThePluginInstalled: true, isJetpackConnected: false)
        sessionManager.defaultSite = updatedSite
        viewModel.onJetpackInstallDismiss()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })
    }

    // MARK: - `accountSettings` row visibility

    func test_accountSettings_section_is_shown_when_authenticated_with_wpcom() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        let stores = DefaultStoresManager(sessionManager: sessionManager)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.accountSettings) })
    }

    func test_accountSettings_section_is_hidden_when_authenticated_without_wpcom() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: false)
        let stores = DefaultStoresManager(sessionManager: sessionManager)
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.accountSettings) })
    }

    func test_domain_is_hidden_when_domainSettings_feature_is_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDomainSettingsEnabled: false)
        stores.updateDefaultStore(.fake().copy(isWordPressComStore: true))
        let viewModel = SettingsViewModel(stores: stores,
                                          storageManager: storageManager,
                                          featureFlagService: featureFlagService)

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
                                          featureFlagService: featureFlagService)

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
                                          featureFlagService: featureFlagService)

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
                                          featureFlagService: featureFlagService)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.domain) })
    }

    func test_sections_contains_whats_new_row_when_announcement_for_this_version_is_available() {
        // Given
        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: storageManager)
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        else {
            return XCTFail("Could not get the current app version")
        }

        waitFor { [weak self] promise in
            self?.stores.whenReceivingAction(ofType: AnnouncementsAction.self) { announcementAction in
                switch announcementAction {
                case .loadSavedAnnouncement(let completion):
                    completion(.success((Announcement.fake().copy(appVersionName: currentVersion,
                                                                  minimumAppVersion: currentVersion,
                                                                  maximumAppVersion: currentVersion),
                                         true)))
                    promise(())
                default:
                    break
                }
            }

            // When
            viewModel.onViewDidLoad()
        }

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.whatsNew) })
    }

    func test_sections_does_not_contain_whats_new_row_when_announcement_is_available_for_past_version() {
        // Given
        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: storageManager)

        waitFor { [weak self] promise in
            self?.stores.whenReceivingAction(ofType: AnnouncementsAction.self) { announcementAction in
                switch announcementAction {
                case .loadSavedAnnouncement(let completion):
                    completion(.success((Announcement.fake().copy(appVersionName: "10.1",
                                                                  minimumAppVersion: "9.9",
                                                                  maximumAppVersion: "11.1"),
                                         true)))
                    promise(())
                default:
                    break
                }
            }

            // When
            viewModel.onViewDidLoad()
        }

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.whatsNew) })
    }

}

private final class MockSettingsPresenter: SettingsViewPresenter {

    var refreshViewContentCalled = false

    func refreshViewContent() {
        refreshViewContentCalled = true
    }
}
