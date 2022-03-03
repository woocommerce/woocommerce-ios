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

    func test_menuElements_include_inbox_and_coupons_when_store_has_eligible_wc_version_and_coupons_enabled() {
        // Given the store is eligible for inbox with only WC plugin and coupons feature is enabled in app settings
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
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

        // Then both inbox and coupons are in the menu
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .inbox, .coupons, .reviews])
    }

    func test_menuElements_include_inbox_when_store_has_min_wcAdmin_version_while_wc_version_is_ineligible() {
        // Given the store is eligible for inbox with WC Admin and coupons feature is enabled in app settings
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                switch systemPluginName {
                case PluginName.wooCommerce:
                    onCompletion(Fixtures.wcPluginIneligibleForInbox)
                case PluginName.wooCommerceAdmin:
                    onCompletion(Fixtures.wcAdminPluginEligibleForInbox)
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
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .inbox, .reviews])
    }

    func test_menuElements_do_not_include_inbox_when_store_has_eligible_wc_version_but_ineliglbe_wcAdmin_version() {
        // Given the store is eligible for inbox with only WC plugin
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                switch systemPluginName {
                case PluginName.wooCommerce:
                    onCompletion(Fixtures.wcPluginEligibleForInbox)
                case PluginName.wooCommerceAdmin:
                    onCompletion(Fixtures.wcAdminPluginIneligibleForInbox)
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
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .reviews])
    }

    func test_menuElements_do_not_include_inbox_when_store_has_ineligible_wc_version_and_no_wcAdmin_plugin() {
        // Given the store is eligible for inbox with WC Admin and coupons feature is enabled in app settings
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

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        // Then both inbox and coupons are in the menu
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .reviews])
    }

    func test_menuElements_do_not_include_inbox_when_store_has_ineligible_wc_version_and_inactive_wcAdmin_plugin() {
        // Given the store is eligible for inbox with WC Admin and coupons feature is enabled in app settings
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                switch systemPluginName {
                case PluginName.wooCommerce:
                    onCompletion(Fixtures.wcPluginIneligibleForInbox)
                case PluginName.wooCommerceAdmin:
                    onCompletion(Fixtures.inactiveWCAdminPluginEligibleForInbox)
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
}

private extension HubMenuViewModelTests {
    enum PluginName {
        static let wooCommerce = "WooCommerce"
        static let wooCommerceAdmin = "WooCommerce Admin"
    }

    enum Fixtures {
        // WooCommerce plugin.
        static let wcPluginIneligibleForInbox = SystemPlugin.fake().copy(version: "3.0.0", active: true)
        static let wcPluginEligibleForInbox = SystemPlugin.fake().copy(version: "6.1.0", active: true)

        // WooCommerce Admin plugin.
        static let wcAdminPluginIneligibleForInbox = SystemPlugin.fake().copy(version: "1.0.0", active: true)
        static let wcAdminPluginEligibleForInbox = SystemPlugin.fake().copy(version: "3.1.0", active: true)
        static let inactiveWCAdminPluginEligibleForInbox = SystemPlugin.fake().copy(version: "6.0.0", active: false)
    }
}
