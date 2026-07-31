import Testing
import Foundation
import Experiments
import Networking
import Yosemite
import YosemiteTestHelpers
import struct Storage.GeneralAppSettingsStorage
@testable import WooCommerce

/// The report is a text artifact, so most of it is pinned by comparing the whole thing: that catches an omitted
/// field, a lost section and a misplaced store band in one assertion, which per-field tests do not.
///
/// The Feature Flags and Experimental Features bodies are redacted from those comparisons — they enumerate
/// `FeatureFlag.allCases` and `BetaFeature.allCases`, so an inline expectation would fail on every unrelated PR
/// that adds a flag. They have their own tests below.
///
/// Serialized because `SessionManager.testingInstance` is backed by a shared `UserDefaults` suite: every test
/// here sets a selected store, and in parallel they overwrite each other's.
@MainActor
@Suite(.serialized)
struct MobileStatusReportProviderTests {

    private let sessionManager: SessionManager
    private let stores: MockStoresManager
    private let storageManager: MockStorageManager
    private let pushNotesManager: MockPushNotificationsManager
    private let posEligibilityService = MockPOSEligibilityService()
    private let posCatalogSettingsService = MockPOSCatalogSettingsService()
    private let appSettings = GeneralAppSettingsStorage(fileStorage: MockInMemoryStorage())

    init() {
        sessionManager = SessionManager.testingInstance
        stores = MockStoresManager(sessionManager: sessionManager)
        storageManager = MockStorageManager()
        pushNotesManager = MockPushNotificationsManager()
        sessionManager.defaultSite = nil
        sessionManager.defaultAccount = nil
        sessionManager.defaultCredentials = nil

        // The provider's `awaitedDispatch` waits out its timeout when nothing answers an action, so the
        // storage-backed lookups are answered "nothing stored" up front; tests override as needed.
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .getStoreID(_, onCompletion):
                onCompletion(nil)
            case let .getPreferredInPersonPaymentGateway(_, onCompletion):
                onCompletion(nil)
            case let .getPOSLastOpenedDate(_, onCompletion):
                onCompletion(nil)
            case let .getPOSLocalCatalogCellularDataAllowed(_, onCompletion):
                onCompletion(false)
            case let .getPOSCatalogFileBlockedByHost(_, onCompletion):
                onCompletion(false)
            default:
                break
            }
        }
    }

    @Test func report_when_no_store_is_selected() async {
        // Given, When
        let report = await makeProvider().generateReport()

        // Then
        #expect(redactingEnumeratedSections(report) == """
        ### Mobile Status Report generated via the WooCommerce iOS app ###
        Field reference: https://github.com/woocommerce/woocommerce-ios/blob/trunk/docs/mobile-status-report.md

        ## App
        Version: 21.3 (2103003)
        Build: appStore

        ## Device
        Model: iPhone17,1
        OS: iOS 18.4
        Free space: 12.40 GB
        Screen: 393x852 pt (phone)
        Device locale: en-US
        App language: en-GB

        ## Connectivity
        Network type: WiFi or Ethernet
        Expensive connection: false
        Low Data Mode: false

        ## Notifications
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

        ## Account & Stores
        WPCom user ID: not logged in
        Connected stores: 0

        ## Feature Flags
        <redacted>

        ## Experimental Features
        <redacted>

        # No store selected
        """)
    }

    @Test func report_when_a_store_is_selected() async throws {
        // Given
        let pushNotesManager = try await givenAFullyPopulatedStore()

        // When
        let report = await makeProvider(pushNotesManager: pushNotesManager)
            .generateReport(siteAddress: "https://typed.example.com")

        // Then
        #expect(redactingEnumeratedSections(report).contains("""
        ## Account & Stores
        WPCom user ID: 12345
        Address given in the form: https://typed.example.com
        Connected stores: 2

        All connected stores:
        https://example.com: Plan: business-bundle Jetpack: installed=true connected=true
        https://other.example.com: Plan: unknown Jetpack: installed=false connected=false

        ## Feature Flags
        <redacted>

        ## Experimental Features
        <redacted>

        # Selected store: https://example.com

        ## Store Details
        Blog ID: 1
        Store ID: store-abc
        Auth method: WPCom
        Jetpack: installed=true connected=true CP=false
        Plan: business-bundle
        Woo core version: 9.4.2

        ## Store Notifications
        Push registration: REGISTERED_BOTH

        ## Payments
        WooPayments: active 8.1.0
        Stripe extension: installed, not active 7.0.0
        In-person payments plugin: WooPayments 8.1.0
        In-person payments onboarding: not evaluated (the merchant has not opened a payments screen since launch)

        ## Point of Sale
        POS tab visible: true
        POS launchable: true
        Catalog strategy: local catalog
        POS last opened: 2023-11-13T22:13:20Z
        Local catalog products: 42
        Local catalog variations: 7
        Local catalog full sync: 2023-11-14T22:13:20Z
        Local catalog incremental sync: never
        Catalog file blocked: false
        Full sync on cellular allowed: true
        """))
    }

    // MARK: - Values a whole-report comparison would not make obvious

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
        #expect(hidden.contains("Reason is logged - search application_log.txt for \"POS tab not visible\" or \"POS cannot be launched\""))
        #expect(!available.contains("Reason is logged"))
    }

    /// Matching the Android report's per-field degradation: the eligibility rows around the catalog read
    /// survive it failing, and `unknown` keeps an unreadable catalog distinct from an empty or unsynced one.
    @Test func a_failing_catalog_read_degrades_its_own_rows_without_taking_the_section_with_it() async {
        // Given
        sessionManager.defaultSite = Yosemite.Site.fake().copy(siteID: 1, url: "https://example.com")
        posEligibilityService.cachedTabVisibility[1] = true
        posCatalogSettingsService.catalogInfoResult = .failure(MockError.anyError)

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("""
        POS tab visible: true
        POS launchable: not evaluated
        """))
        #expect(report.contains("""
        Local catalog products: unknown
        Local catalog variations: unknown
        Local catalog full sync: unknown
        Local catalog incremental sync: unknown
        Catalog file blocked: false
        """))
    }

    // MARK: - Feature flags

    /// An aged-out cache is not what `isRemoteFeatureFlagEnabled` returns, so listing its values would describe
    /// behaviour the app is not exhibiting.
    @Test func remote_flags_are_not_listed_when_none_are_in_effect() async {
        // Given
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .loadRemoteFeatureFlagsInEffect(completion) = action {
                completion(nil)
            }
        }

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("Remote values loaded: false (nothing fetched this session, or the last fetch aged out)"))
        #expect(!report.contains("(remote)"))
    }

    @Test func remote_flags_report_the_server_value_and_the_keys_it_omitted() async {
        // Given
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .loadRemoteFeatureFlagsInEffect(completion) = action {
                completion([.pointOfSale: true])
            }
        }

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("Remote values loaded: true"))
        #expect(report.contains("pointOfSale: true (remote)"))
        #expect(report.contains("qrCodeLogin: not returned by server"))
    }

    /// The deauthenticated stores manager drops actions for stores it does not run, and a dropped dispatch has
    /// no completion coming. The report must degrade to the fallback value rather than wait on it forever.
    @Test func an_unanswered_dispatch_degrades_instead_of_stalling_the_report() async {
        // Given: nothing ever answers the feature-flag action
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { _ in }

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("Remote values loaded: false (nothing fetched this session, or the last fetch aged out)"))
    }

    @Test func experimental_features_lists_every_toggle_from_the_settings_screen() async throws {
        // Given
        try appSettings.setValue(true, for: BetaFeature.viewAddOns.settingsKey)

        // When
        let report = await makeProvider().generateReport()

        // Then
        let lines = section("## Experimental Features", in: report)
        #expect(lines.count == BetaFeature.allCases.count)
        // The stable English report label, not `BetaFeature.title`: that is localized UI copy, and a report
        // generated on a non-English device must still carry greppable English keys.
        #expect(lines.contains("Product add-ons: true"))
    }
}

// MARK: - Helpers

private extension MobileStatusReportProviderTests {

    func makeProvider(pushNotesManager: PushNotesManager? = nil) -> MobileStatusReportProvider {
        MobileStatusReportProvider(systemSnapshot: { .fixture() },
                                   pushNotesManager: pushNotesManager ?? self.pushNotesManager,
                                   stores: stores,
                                   storageManager: storageManager,
                                   onboardingStateCache: CardPresentPaymentOnboardingStateCache(),
                                   posEligibilityService: posEligibilityService,
                                   posCatalogSettingsService: posCatalogSettingsService,
                                   featureFlagService: MockFeatureFlagService(),
                                   generalAppSettings: appSettings)
    }

    func givenAFullyPopulatedStore() async throws -> MockPushNotificationsManager {
        sessionManager.defaultSite = Yosemite.Site.fake().copy(siteID: 1,
                                                               name: "A",
                                                               url: "https://example.com",
                                                               plan: "business-bundle",
                                                               isJetpackThePluginInstalled: true,
                                                               isJetpackConnected: true)
        sessionManager.defaultAccount = Account(userID: 12345,
                                                displayName: "",
                                                email: "",
                                                username: "",
                                                gravatarUrl: nil)
        sessionManager.defaultCredentials = .wpcom(username: "u", authToken: "t", siteAddress: "https://example.com")

        try await insert(sites: [Yosemite.Site.fake().copy(siteID: 1, name: "A", url: "https://example.com",
                                                           plan: "business-bundle",
                                                           isJetpackThePluginInstalled: true, isJetpackConnected: true,
                                                           isWooCommerceActive: true),
                                 Yosemite.Site.fake().copy(siteID: 2, name: "B", url: "https://other.example.com",
                                                           plan: "",
                                                           isJetpackThePluginInstalled: false, isJetpackConnected: false,
                                                           isWooCommerceActive: true)],
                         plugins: [SitePlugin.fake().copy(siteID: 1, plugin: "woocommerce/woocommerce", version: "9.4.2"),
                                   SitePlugin.fake().copy(siteID: 1, plugin: "woocommerce-payments/woocommerce-payments",
                                                          status: .active, version: "8.1.0"),
                                   SitePlugin.fake().copy(siteID: 1,
                                                          plugin: "woocommerce-gateway-stripe/woocommerce-gateway-stripe",
                                                          status: .inactive, version: "7.0.0")])

        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .getStoreID(_, onCompletion):
                onCompletion("store-abc")
            case let .getPreferredInPersonPaymentGateway(_, onCompletion):
                onCompletion(CardPresentPaymentsPlugin.wcPay.gatewayID)
            case let .getPOSLastOpenedDate(_, onCompletion):
                onCompletion(Date(timeIntervalSince1970: 1_699_913_600))
            case let .getPOSLocalCatalogCellularDataAllowed(_, onCompletion):
                onCompletion(true)
            case let .getPOSCatalogFileBlockedByHost(_, onCompletion):
                onCompletion(false)
            default:
                break
            }
        }

        posEligibilityService.cachedTabVisibility[1] = true
        posEligibilityService.cachedLastKnownPOSEligibility[1] = true
        stores.testPOSCatalogEligibilityChecker = MockPOSLocalCatalogEligibilityService(cachedStates: [1: .eligible])
        posCatalogSettingsService.catalogInfoResult = .success(
            .init(productCount: 42,
                  variationCount: 7,
                  lastFullSyncDate: Date(timeIntervalSince1970: 1_700_000_000),
                  lastIncrementalSyncDate: nil)
        )

        return MockPushNotificationsManager(mockedDeviceID: "device-id", siteIDsRegisteredForWooPNs: [1])
    }

    func insert(sites: [Yosemite.Site], plugins: [SitePlugin]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storageManager.performAndSave({ storage in
                sites.forEach { storage.insertNewObject(ofType: StorageSite.self).update(with: $0) }
                plugins.forEach { storage.insertNewObject(ofType: StorageSitePlugin.self).update(with: $0) }
            }, completion: {
                continuation.resume()
            }, on: .main)
        }
    }

    /// Replaces the bodies of the two sections that enumerate every known flag and beta toggle, so an unrelated
    /// addition to either list does not fail a whole-report comparison.
    func redactingEnumeratedSections(_ report: String) -> String {
        ["## Feature Flags", "## Experimental Features"].reduce(report) { report, heading in
            let lines = report.components(separatedBy: "\n")
            guard let start = lines.firstIndex(of: heading) else {
                return report
            }
            // Sections end at the next `## ` section heading or the `# ` selected-store band — but not at the
            // `### ` subsection headings inside the Feature Flags body.
            let body = Array(lines[lines.index(after: start)...].prefix { !$0.hasPrefix("## ") && !$0.hasPrefix("# ") })
            // The blank line before the next heading belongs to the layout, not the section, so it survives.
            let separators = Array(repeating: "", count: body.reversed().prefix { $0.isEmpty }.count)
            return (lines[...start] + ["<redacted>"] + separators + lines[(start + 1 + body.count)...])
                .joined(separator: "\n")
        }
    }

    func section(_ heading: String, in report: String) -> [String] {
        let lines = report.components(separatedBy: "\n")
        guard let start = lines.firstIndex(of: heading) else {
            return []
        }
        return lines[lines.index(after: start)...].prefix { !$0.hasPrefix("## ") && !$0.hasPrefix("# ") }.filter { !$0.isEmpty }
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
