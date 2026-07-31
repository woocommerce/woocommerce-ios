import Testing
import Foundation
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

/// The report is a text artifact, so it is pinned by comparing the whole thing: that catches an omitted field, a
/// lost section and a broken scope in one assertion, which per-field tests do not.
///
/// Serialized because `SessionManager.testingInstance` is backed by a shared `UserDefaults` suite: tests here set
/// a selected store, and in parallel they overwrite each other's.
@MainActor
@Suite(.serialized)
struct MobileStatusReportProviderTests {

    private let sessionManager: SessionManager
    private let stores: MockStoresManager
    private let storageManager: MockStorageManager
    private let posEligibilityService = MockPOSEligibilityService()
    private let posCatalogSettingsService = MockPOSCatalogSettingsService()

    init() {
        sessionManager = SessionManager.testingInstance
        stores = MockStoresManager(sessionManager: sessionManager)
        storageManager = MockStorageManager()
        sessionManager.defaultSite = nil
        sessionManager.defaultAccount = nil
        sessionManager.defaultCredentials = nil
    }

    @Test func report_contents() async {
        // Given, When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report == """
        ### Mobile Status Report generated via the WooCommerce iOS app ###
        Scopes: (app-wide) values cover the whole app on this device. (selected store: ...) values cover only the named store.
        Field reference: https://github.com/woocommerce/woocommerce-ios/blob/trunk/docs/mobile-status-report.md

        ## App (app-wide)
        Version: 21.3 (2103003)
        Build: appStore

        ## Device (app-wide)
        Model: iPhone17,1
        OS: iOS 18.4
        Free space: 12.40 GB
        Screen: 393x852 pt (phone)
        Device locale: en-US
        App language: en-GB

        ## Connectivity (app-wide)
        Network type: WiFi or Ethernet
        Expensive connection: false
        Low Data Mode: false

        ## Notifications (app-wide)
        APNs environment: production
        Authorization status: authorized
        Alerts: enabled
        Sounds: enabled
        Lock screen: enabled
        Time-sensitive: enabled
        Scheduled summary: disabled
        APNs device token: missing
        Woo push token ID: missing
        Background refresh: available
        Low Power Mode: false

        ## Account & Stores (app-wide)
        WPCom user ID: not logged in
        Connected stores: 0

        ## Store Details (no store selected)
        Not applicable while no store is selected

        ## Store Notifications (no store selected)
        Not applicable while no store is selected

        ## Payments (no store selected)
        Not applicable while no store is selected

        ## Point of Sale (no store selected)
        Not applicable while no store is selected
        """)
    }

    @Test func point_of_sale_points_at_the_log_only_when_something_is_unavailable() async {
        // Given
        sessionManager.defaultSite = Yosemite.Site.fake().copy(siteID: 1, url: "https://example.com")
        posEligibilityService.cachedTabVisibility[1] = false

        // When
        let hidden = await makeProvider().generateReport()
        posEligibilityService.cachedTabVisibility[1] = true
        posEligibilityService.cachedLastKnownPOSEligibility[1] = true
        let available = await makeProvider().generateReport()

        // Then
        #expect(hidden.contains("Reason is logged - search application_log.txt for the POS eligibility entries"))
        #expect(!available.contains("Reason is logged"))
    }

    @Test func a_failing_section_degrades_without_taking_the_report_with_it() async {
        // Given
        sessionManager.defaultSite = Yosemite.Site.fake().copy(siteID: 1, url: "https://example.com")
        posCatalogSettingsService.catalogInfoResult = .failure(MockError.anyError)

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("""
        ## Point of Sale (selected store: https://example.com)
        Info not found
        """))
        #expect(report.contains("## Payments"))
    }

    /// Reporting these as "not installed" would send triage the opposite way from what is true.
    @Test func an_empty_plugin_cache_is_not_reported_as_plugins_being_absent() async {
        // Given
        sessionManager.defaultSite = Yosemite.Site.fake().copy(siteID: 1, url: "https://example.com")

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("Payment plugins: unknown (none cached for this store)"))
        #expect(!report.contains("WooPayments: not installed"))
    }

    @Test(arguments: [(true, "device-id", "REGISTERED_BOTH"),
                      (true, nil, "REGISTERED_WOO_ONLY"),
                      (false, "device-id", "REGISTERED_WPCOM_ONLY"),
                      (false, nil, "UNREGISTERED")])
    func push_registration_covers_both_systems(wooRegistered: Bool, deviceID: String?, expected: String) async {
        // Given
        sessionManager.defaultSite = Yosemite.Site.fake().copy(siteID: 1, url: "https://example.com")
        let pushNotesManager = MockPushNotificationsManager(mockedDeviceID: deviceID,
                                                            siteIDsRegisteredForWooPNs: wooRegistered ? [1] : [])

        // When
        let report = await makeProvider(pushNotesManager: pushNotesManager).generateReport()

        // Then
        #expect(report.contains("Push registration: \(expected)"))
    }

    @Test func no_push_token_reaches_the_report_in_full() async {
        // Given
        let pushNotesManager = MockPushNotificationsManager(deviceToken: "0123456789abcdef",
                                                            wooPushNotificationToken: "4815162342")

        // When
        let report = await makeProvider(pushNotesManager: pushNotesManager).generateReport()

        // Then
        #expect(report.contains("APNs device token: present (…abcdef)"))
        #expect(!report.contains("0123456789abcdef"))
        #expect(report.contains("Woo push token ID: present (…162342)"))
        #expect(!report.contains("4815162342"))
    }
}

// MARK: - Helpers

private extension MobileStatusReportProviderTests {

    func makeProvider(pushNotesManager: PushNotesManager = MockPushNotificationsManager())
    -> MobileStatusReportProvider {
        MobileStatusReportProvider(systemSnapshot: { .fixture() },
                                   pushNotesManager: pushNotesManager,
                                   stores: stores,
                                   storageManager: storageManager,
                                   onboardingStateCache: CardPresentPaymentOnboardingStateCache(),
                                   posEligibilityService: posEligibilityService,
                                   posCatalogSettingsService: posCatalogSettingsService)
    }
}

private extension MobileStatusReportSystemSnapshot {
    static func fixture() -> Self {
        MobileStatusReportSystemSnapshot(version: "21.3 (2103003)",
                                         build: "appStore",
                                         model: "iPhone17,1",
                                         os: "iOS 18.4",
                                         freeSpace: "12.40 GB",
                                         screen: "393x852 pt (phone)",
                                         deviceLocale: "en-US",
                                         appLanguage: "en-GB",
                                         networkType: "WiFi or Ethernet",
                                         expensiveConnection: "false",
                                         lowDataMode: "false",
                                         apnsEnvironment: "production",
                                         authorizationStatus: "authorized",
                                         alerts: "enabled",
                                         sounds: "enabled",
                                         lockScreen: "enabled",
                                         timeSensitive: "enabled",
                                         scheduledSummary: "disabled",
                                         backgroundRefresh: "available",
                                         lowPowerMode: "false")
    }
}
