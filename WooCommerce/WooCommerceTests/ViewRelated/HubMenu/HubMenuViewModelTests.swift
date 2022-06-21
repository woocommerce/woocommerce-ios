import XCTest

@testable import WooCommerce
@testable import Yosemite

final class HubMenuViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 606

    func test_menuElements_do_not_include_inbox_when_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(viewModel.menuElements.contains(.inbox))
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
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .inbox, .coupons, .reviews])
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

        // Then only coupons is in the menu
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .coupons, .reviews])
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
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .reviews])
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
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .coupons, .reviews])
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

        // Then
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .reviews])
    }
    func test_hubMenu_returns_storeURL_when_site_has_storeURL() {
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
    func test_hubMenu_returns_adminURL_when_site_has_adminURL() {
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
    func test_hubMenu_returns_woocommerce_fallback_URL_when_site_storeURL_is_nil() {
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
    func test_hubMenu_returns_adminURL_fallback_when_site_adminURL_is_nil() {
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
    func test_hubMenu_returns_adminURL_fallback_when_site_adminURL_is_empty() {
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
