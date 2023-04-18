import XCTest

@testable import WooCommerce
@testable import Yosemite

final class HubMenuViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 606

    func test_viewDidAppear_then_posts_notification() {
        // Given
        let viewModel = HubMenuViewModel(siteID: sampleSiteID)
        expectation(forNotification: .hubMenuViewDidAppear, object: nil, handler: nil)

        // When
        viewModel.viewDidAppear()

        // Then
        waitForExpectations(timeout: Constants.expectationTimeout)
    }

    func test_menuElements_do_not_include_inbox_when_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService)

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Inbox.id
        }))
    }

    func test_menuElements_include_inbox_and_coupons_when_store_has_eligible_wc_version() {
        // Given the store is eligible for inbox with only WC plugin and coupons feature is enabled in app settings
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCouponManagementFeatureSwitchState(let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                switch systemPluginName {
                case PluginName.wooCommerce:
                    onCompletion(Fixtures.wcPluginEligibleForInbox)
                default:
                    onCompletion(nil)
                }
            default:
                break
            }
        }

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        // Then both inbox and coupons are in the menu
        XCTAssertNotNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Inbox.id
        }))

        XCTAssertNotNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Coupons.id
        }))
    }

    func test_menuElements_do_not_include_inbox_when_store_has_ineligible_wc_version() {
        // Given the store is ineligible WC version for inbox and coupons feature is enabled in app settings
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                switch systemPluginName {
                case PluginName.wooCommerce:
                    onCompletion(Fixtures.wcPluginIneligibleForInbox)
                default:
                    onCompletion(nil)
                }
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCouponManagementFeatureSwitchState(let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Inbox.id
        }))
    }

    func test_menuElements_do_not_include_inbox_and_coupons_when_store_has_ineligible_wc_version_and_coupons_disabled() {
        // Given the store is ineligible WC version for inbox and coupons feature is disabled in app settings
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                switch systemPluginName {
                case PluginName.wooCommerce:
                    onCompletion(Fixtures.wcPluginIneligibleForInbox)
                default:
                    onCompletion(nil)
                }
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCouponManagementFeatureSwitchState(let onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        // Then neither inbox nor coupons is in the menu
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Inbox.id
        }))

        XCTAssertNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Coupons.id
        }))
    }

    func test_menuElements_include_coupons_when_couponManagement_is_enabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCouponManagementFeatureSwitchState(let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        // Then
        XCTAssertNotNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Coupons.id
        }))
    }

    func test_menuElements_do_not_include_coupons_when_couponManagement_is_not_enabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCouponManagementFeatureSwitchState(let onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        XCTAssertNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Coupons.id
        }))
    }

    func test_storeURL_when_site_has_storeURL_then_returns_storeURL() {
        // Given
        let sampleStoreURL = "https://testshop.com/"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(url: sampleStoreURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)

        // Then
        XCTAssertEqual(viewModel.storeURL, try sampleStoreURL.asURL())
    }
    func test_woocommerceAdminURL_when_site_has_adminURL_then_returns_adminURL() {
        // Given
        let sampleAdminURL = "https://testshop.com/wp-admin/"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)

        // Then
        XCTAssertEqual(viewModel.woocommerceAdminURL, try sampleAdminURL.asURL())
    }
    func test_storeURL_when_storeURL_is_nil_then_returns_woocommerce_fallback_url() {
        // Given
        let sampleStoreURL: String? = nil
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(url: sampleStoreURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)
        // Then
        XCTAssertNotNil(viewModel.storeURL)
        XCTAssertEqual(viewModel.storeURL, WooConstants.URLs.blog.asURL())
    }
    func test_woocommerceAdminURL_when_adminURL_is_nil_then_returns_adminURL() {
        // Given
        let sampleStoreURL = "https://testshop.com"
        let sampleAdminURL: String? = nil
        let expectedAdminURL = "https://testshop.com/wp-admin"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(url: sampleStoreURL, adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)
        // Then
        XCTAssertNotNil(viewModel.woocommerceAdminURL)
        XCTAssertEqual(viewModel.woocommerceAdminURL, try URL(string: expectedAdminURL)?.asURL())
    }
    func test_woocommerceAdminURL_when_adminURL_is_empty_then_returns_adminURL() {
        // Given
        let sampleStoreURL = "https://testshop.com"
        let sampleAdminURL = ""
        let expectedAdminURL = "https://testshop.com/wp-admin"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(url: sampleStoreURL, adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)
        // Then
        XCTAssertNotNil(viewModel.woocommerceAdminURL)
        XCTAssertEqual(viewModel.woocommerceAdminURL, try URL(string: expectedAdminURL)?.asURL())
    }

    func test_switchStoreEnabled_returns_true_when_logged_in_with_wpcom() {
        // Given
        let sampleStoreURL = "https://testshop.com"
        let sampleAdminURL = ""
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        let site = Site.fake().copy(url: sampleStoreURL, adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)

        // Then
        XCTAssertTrue(viewModel.switchStoreEnabled)
    }

    func test_switchStoreEnabled_returns_false_when_logged_in_without_wpcom() {
        // Given
        let sampleStoreURL = "https://testshop.com"
        let sampleAdminURL = ""
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: false)
        let site = Site.fake().copy(url: sampleStoreURL, adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)

        // Then
        XCTAssertFalse(viewModel.switchStoreEnabled)
    }

    func test_shouldAuthenticateAdminPage_returns_true_when_logged_in_with_wpcom_to_wpcom_site() {
        // Given
        let sampleStoreURL = "https://testshop.com"
        let sampleAdminURL = ""
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        let site = Site.fake().copy(url: sampleStoreURL, adminURL: sampleAdminURL, isWordPressComStore: true)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)

        // Then
        XCTAssertTrue(viewModel.shouldAuthenticateAdminPage)
    }

    func test_shouldAuthenticateAdminPage_returns_true_when_logged_in_without_wpcom_to_self_hosted_site() {
        // Given
        let sampleStoreURL = "https://testshop.com"
        let sampleAdminURL = ""
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: false)
        let site = Site.fake().copy(url: sampleStoreURL, adminURL: sampleAdminURL, isWordPressComStore: false)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)

        // Then
        XCTAssertTrue(viewModel.shouldAuthenticateAdminPage)
    }

    func test_shouldAuthenticateAdminPage_returns_false_when_logged_in_with_wpcom_to_self_hosted_site() {
        // Given
        let sampleStoreURL = "https://testshop.com"
        let sampleAdminURL = ""
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        let site = Site.fake().copy(url: sampleStoreURL, adminURL: sampleAdminURL, isWordPressComStore: false)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         stores: stores)

        // Then
        XCTAssertFalse(viewModel.shouldAuthenticateAdminPage)
    }

    func test_menuElements_include_upgrades_on_wp_com_sites() {
        // Given
        let featureFlagService = MockFeatureFlagService(isFreeTrial: true)

        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        XCTAssertNotNil(viewModel.settingsElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Upgrades.id
        }))
    }

    func test_menuElements_does_not_include_upgrades_on_self_hosted_sites() {
        // Given
        let featureFlagService = MockFeatureFlagService(isFreeTrial: true)

        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(isWordPressComStore: false)
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        XCTAssertNil(viewModel.settingsElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Upgrades.id
        }))
    }

}

private extension HubMenuViewModelTests {
    enum PluginName {
        static let wooCommerce = "WooCommerce"
    }

    enum Fixtures {
        // TODO: 6148 - Update the minimum WC version with inbox filtering.
        static let wcPluginIneligibleForInbox = SystemPlugin.fake().copy(version: "3.0.0", active: true)
        static let wcPluginEligibleForInbox = SystemPlugin.fake().copy(version: "6.1.0", active: true)
    }
}
