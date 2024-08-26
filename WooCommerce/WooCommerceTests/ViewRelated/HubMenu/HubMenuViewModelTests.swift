import SwiftUI
import XCTest

@testable import WooCommerce
@testable import Yosemite
@testable import Storage

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
        waitUntil {
            blazeEligibilityChecker.isSiteEligibleInvoked
        }

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
    func test_navigateToDestination_replaces_navigationPath_with_specified_destination() throws {
        // Given
        let generalAppSettings = try mockGeneralAppSettingsStorage(isInAppPurchaseEnabled: true)
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let googleAdsEligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: true)
        var inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        // Setting site ID is required before setting `Site`.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID, isWordPressComStore: true))

        let navigationPath = NavigationPath(["testPath1", "testPath2"])
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker(),
                                         stores: stores,
                                         generalAppSettings: generalAppSettings,
                                         inboxEligibilityChecker: inboxEligibilityChecker,
                                         blazeEligibilityChecker: blazeEligibilityChecker,
                                         googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        viewModel.navigationPath = navigationPath
        XCTAssertEqual(viewModel.navigationPath.count, 2)

        let expectedMenusAndDestinations: [HubMenuNavigationDestination: HubMenuItem] = [
            .settings: HubMenuViewModel.Settings(),
            .payments: HubMenuViewModel.Payments(),
            .inAppPurchase: HubMenuViewModel.InAppPurchases(),
            .subscriptions: HubMenuViewModel.Subscriptions(),
            .blaze: HubMenuViewModel.Blaze(),
            .wooCommerceAdmin: HubMenuViewModel.WoocommerceAdmin(),
            .viewStore: HubMenuViewModel.ViewStore(),
            .coupons: HubMenuViewModel.Coupons(),
            .reviews: HubMenuViewModel.Reviews(),
            .inbox: HubMenuViewModel.Inbox(),
            .customers: HubMenuViewModel.Customers(),
            .pointOfSales: HubMenuViewModel.PointOfSaleEntryPoint()
        ]

        /// Counting the cases to ensure new cases are tested.
        viewModel.setupMenuElements()
        waitUntil {
            expectedMenusAndDestinations.count == viewModel.settingsElements.count + viewModel.generalElements.count
        }

        for (expected, menuItem) in expectedMenusAndDestinations {
            // When
            let destination = menuItem.navigationDestination
            viewModel.navigateToDestination(destination)

            // Then
            XCTAssertEqual(destination, expected)
            XCTAssertEqual(viewModel.navigationPath.count, 1)
            XCTAssertEqual(viewModel.navigationPath, NavigationPath([expected]))
        }
    }

    @MainActor
    func test_navigateToDestination_without_destination_leaves_navigationPath_intact() {
        // Given
        let navigationPath = NavigationPath(["testPath1", "testPath2"])
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker())
        viewModel.navigationPath = navigationPath

        // When
        viewModel.navigateToDestination(nil)

        // Then
        XCTAssertEqual(viewModel.navigationPath.count, 2)
        XCTAssertEqual(viewModel.navigationPath, navigationPath)
    }

    @MainActor
    func test_showReviewDetails_updates_navigationPath_correctly() {
        // Given
        let parcel = ProductReviewFromNoteParcel.fake().copy(note: .fake().copy(noteID: 123))
        let viewModel = HubMenuViewModel(siteID: sampleSiteID,
                                         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker())

        // When
        viewModel.showReviewDetails(using: parcel)

        // Then
        XCTAssertEqual(viewModel.navigationPath.count, 1)
        XCTAssertEqual(viewModel.navigationPath, NavigationPath([HubMenuNavigationDestination.reviewDetails(parcel: parcel)]))
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
    func mockGeneralAppSettingsStorage(isInAppPurchaseEnabled: Bool) throws -> GeneralAppSettingsStorage {
        let fileStorage = MockInMemoryStorage()
        let storage = GeneralAppSettingsStorage(fileStorage: fileStorage)
        var settings = GeneralAppSettings.default
        settings.isInAppPurchasesSwitchEnabled = isInAppPurchaseEnabled
        try storage.saveSettings(settings)
        return storage
    }
}
