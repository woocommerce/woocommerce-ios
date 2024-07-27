import SwiftUI
import XCTest

@testable import WooCommerce
@testable import Yosemite

final class HubMenuViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 606

    @MainActor
    func test_viewDidAppear_then_posts_notification() {
        // Given
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker())
        expectation(forNotification: .hubMenuViewDidAppear, object: nil, handler: nil)

        // When
        viewModel.viewDidAppear()

        // Then
        waitForExpectations(timeout: Constants.expectationTimeout)
    }

    @MainActor
    func test_menuElements_do_not_include_inbox_when_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         featureFlagService: featureFlagService)

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Inbox.id
        }))
    }

    @MainActor
    func test_menuElements_include_inbox_when_store_has_eligible_wc_version() {
        // Given
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         inboxEligibilityChecker: inboxEligibilityChecker)

        viewModel.setupMenuElements()

        // Then inbox is in the menu
        XCTAssertNotNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Inbox.id
        }))
    }

    @MainActor
    func test_generalMenuElements_include_the_correct_default_elements() {
        // Given
        let inboxEligibilityChecker = MockInboxEligibilityChecker()

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         inboxEligibilityChecker: inboxEligibilityChecker)

        viewModel.setupMenuElements()

        // Then
        let expectedElementsIDs = Set([
            HubMenuViewModel.WoocommerceAdmin.id,
            HubMenuViewModel.ViewStore.id,
            HubMenuViewModel.Coupons.id,
            HubMenuViewModel.Reviews.id,
            HubMenuViewModel.Customers.id
        ])
        let generalElementsIds = Set(viewModel.generalElements.map { $0.self.id })
        XCTAssertTrue(expectedElementsIDs.isSubset(of: generalElementsIds))
    }

    @MainActor
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

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         featureFlagService: featureFlagService,
                                         stores: stores)
        viewModel.setupMenuElements()

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Inbox.id
        }))
    }

    @MainActor
    func test_generalElements_does_not_include_blaze_when_default_site_is_not_set() {
        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker())
        viewModel.setupMenuElements()

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { $0.id == HubMenuViewModel.Blaze.id }))
    }

    @MainActor
    func test_generalElements_does_not_include_blaze_when_site_is_not_eligible_for_blaze() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: false)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         blazeEligibilityChecker: blazeEligibilityChecker)
        viewModel.setupMenuElements()

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { $0.id == HubMenuViewModel.Blaze.id }))
    }

    @MainActor
    func test_generalElements_includes_blaze_after_payments_when_site_is_eligible_for_blaze() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         blazeEligibilityChecker: blazeEligibilityChecker)

        viewModel.setupMenuElements()

        // Then
        let blazeIndex = try XCTUnwrap(viewModel.generalElements.firstIndex(where: { $0.id == HubMenuViewModel.Blaze.id }))
        XCTAssertEqual(viewModel.generalElements[blazeIndex - 1].id, HubMenuViewModel.Payments.id)
    }

    @MainActor
    func test_generalElements_does_not_include_google_ads_when_default_site_is_not_set() {
        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker())
        viewModel.setupMenuElements()

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { $0.id == HubMenuViewModel.GoogleAds.id }))
    }

    @MainActor
    func test_generalElements_does_not_include_google_ads_when_site_is_not_eligible() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        let checker = MockGoogleAdsEligibilityChecker(isEligible: false)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         googleAdsEligibilityChecker: checker)
        waitUntil {
            checker.siteEligibilityCheckTriggered
        }
        viewModel.setupMenuElements()

        // Then
        XCTAssertNil(viewModel.generalElements.firstIndex(where: { $0.id == HubMenuViewModel.GoogleAds.id }))
    }

    @MainActor
    func test_generalElements_includes_google_ads_when_site_is_eligible() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        let checker = MockGoogleAdsEligibilityChecker(isEligible: true)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         googleAdsEligibilityChecker: checker)
        waitUntil {
            checker.siteEligibilityCheckTriggered
        }
        viewModel.setupMenuElements()

        // Then
        let index = try XCTUnwrap(viewModel.generalElements.firstIndex(where: { $0.id == HubMenuViewModel.GoogleAds.id }))
        XCTAssertEqual(viewModel.generalElements[index - 1].id, HubMenuViewModel.Payments.id)
    }

    @MainActor
    func test_storeURL_when_site_has_storeURL_then_returns_storeURL() {
        // Given
        let sampleStoreURL = "https://testshop.com/"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(url: sampleStoreURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)

        // Then
        XCTAssertEqual(viewModel.storeURL, try sampleStoreURL.asURL())
    }

    @MainActor
    func test_woocommerceAdminURL_when_site_has_adminURL_then_returns_adminURL() {
        // Given
        let sampleAdminURL = "https://testshop.com/wp-admin/"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)

        // Then
        XCTAssertEqual(viewModel.woocommerceAdminURL, try sampleAdminURL.asURL())
    }

    @MainActor
    func test_storeURL_when_storeURL_is_nil_then_returns_woocommerce_fallback_url() {
        // Given
        let sampleStoreURL: String? = nil
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(url: sampleStoreURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: site.siteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)
        // Then
        XCTAssertNotNil(viewModel.storeURL)
        XCTAssertEqual(viewModel.storeURL, WooConstants.URLs.blog.asURL())
    }

    @MainActor
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
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)
        // Then
        XCTAssertNotNil(viewModel.woocommerceAdminURL)
        XCTAssertEqual(viewModel.woocommerceAdminURL, try URL(string: expectedAdminURL)?.asURL())
    }

    @MainActor
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
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)
        // Then
        XCTAssertNotNil(viewModel.woocommerceAdminURL)
        XCTAssertEqual(viewModel.woocommerceAdminURL, try URL(string: expectedAdminURL)?.asURL())
    }

    @MainActor
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
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)

        // Then
        XCTAssertTrue(viewModel.switchStoreEnabled)
    }

    @MainActor
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
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)

        // Then
        XCTAssertFalse(viewModel.switchStoreEnabled)
    }

    @MainActor
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
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)

        // Then
        XCTAssertTrue(viewModel.shouldAuthenticateAdminPage)
    }

    @MainActor
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
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)

        // Then
        XCTAssertTrue(viewModel.shouldAuthenticateAdminPage)
    }

    @MainActor
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
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)

        // Then
        XCTAssertFalse(viewModel.shouldAuthenticateAdminPage)
    }

    @MainActor
    func test_menuElements_include_subscriptions_on_wp_com_sites_if_not_free_trial() {
        // Given
        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)
        viewModel.setupMenuElements()

        XCTAssertNotNil(viewModel.settingsElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Subscriptions.id
        }))
    }

    @MainActor
    func test_menuElements_does_not_include_subscriptions_on_wp_com_free_trial_sites() {
        // Given
        let freeTrialPlanSlug = "ecommerce-trial-bundle-monthly"
        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(plan: freeTrialPlanSlug, isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)
        viewModel.setupMenuElements()

        XCTAssertNil(viewModel.settingsElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Subscriptions.id
        }))
    }

    @MainActor
    func test_menuElements_does_not_include_subscriptions_on_self_hosted_sites() {
        // Given
        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(isWordPressComStore: false)
        let stores = MockStoresManager(sessionManager: sessionManager)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores)
        viewModel.setupMenuElements()

        XCTAssertNil(viewModel.settingsElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Subscriptions.id
        }))
    }

    @MainActor
    func test_menuElements_include_customers() {
        // Given
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker())

        // When
        viewModel.setupMenuElements()

        // Then
        XCTAssertNotNil(viewModel.generalElements.firstIndex(where: { item in
            item.id == HubMenuViewModel.Customers.id
        }))
    }

    @MainActor
    func test_showPayments_replaces_navigationPath_with_payments() {
        // Given
        var navigationPath = NavigationPath(["testPath1", "testPath2"])
        navigationPath.append(HubMenuNavigationDestination.payments)
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker())
        viewModel.navigationPath = navigationPath
        XCTAssertEqual(viewModel.navigationPath.count, 3)

        // When
        viewModel.showPayments()

        // Then
        XCTAssertEqual(viewModel.navigationPath.count, 1)
        XCTAssertEqual(viewModel.navigationPath, NavigationPath([HubMenuNavigationDestination.payments]))
    }

    @MainActor
    func test_hasGoogleAdsCampaigns_is_false_when_site_has_no_campaigns() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        var fetchAdsCampaignsTriggered = false
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .fetchAdsCampaigns(_, onCompletion):
                onCompletion(.success([]))
                fetchAdsCampaignsTriggered = true
            default:
                break
            }
        }

        let eligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: true)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         googleAdsEligibilityChecker: eligibilityChecker)
        viewModel.refreshGoogleAdsCampaignCheck()
        waitUntil {
            fetchAdsCampaignsTriggered
        }

        // Then
        XCTAssertFalse(viewModel.hasGoogleAdsCampaigns)
    }

    @MainActor
    func test_hasGoogleAdsCampaigns_is_true_when_site_has_campaigns() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID))

        var fetchAdsCampaignsTriggered = false
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .fetchAdsCampaigns(_, onCompletion):
                let campaign = GoogleAdsCampaign.fake().copy(id: 134254)
                onCompletion(.success([campaign]))
                fetchAdsCampaignsTriggered = true
            default:
                break
            }
        }

        let eligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: true)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         googleAdsEligibilityChecker: eligibilityChecker)
        viewModel.refreshGoogleAdsCampaignCheck()
        waitUntil {
            fetchAdsCampaignsTriggered
        }

        // Then
        XCTAssertTrue(viewModel.hasGoogleAdsCampaigns)
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
