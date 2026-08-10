import Testing
import Foundation
import Experiments
import Networking
import Yosemite
import YosemiteTestHelpers
import struct Storage.GeneralAppSettingsStorage
@testable import WooCommerce

/// The report is a text artifact, so most of it is pinned by comparing the whole thing: that catches an omitted
/// field and a lost section in one assertion, which per-field tests do not.
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
    private let appSettings = GeneralAppSettingsStorage(fileStorage: MockInMemoryStorage())

    init() {
        sessionManager = SessionManager.testingInstance
        stores = MockStoresManager(sessionManager: sessionManager)
        storageManager = MockStorageManager()
        pushNotesManager = MockPushNotificationsManager()
        sessionManager.defaultSite = nil
        sessionManager.defaultAccount = nil
        sessionManager.defaultCredentials = nil
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
        Metered connection: false
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
        """)
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

    @Test func every_connected_woo_store_is_listed_with_its_plan_and_jetpack_state() async {
        // Given
        await insert(sites: [
            .fake().copy(siteID: 1,
                         name: "Alpha",
                         url: "https://alpha.example.com",
                         plan: "business-bundle",
                         isJetpackThePluginInstalled: true,
                         isJetpackConnected: true,
                         isWooCommerceActive: true),
            .fake().copy(siteID: 2,
                         name: "Beta",
                         url: "https://beta.example.com",
                         plan: "",
                         isJetpackThePluginInstalled: false,
                         isJetpackConnected: false,
                         isWooCommerceActive: true),
            // A WPCom site without WooCommerce: on the account, but not a store the count or list may include.
            .fake().copy(siteID: 3,
                         name: "Blog",
                         url: "https://blog.example.com",
                         isWooCommerceActive: false)
        ])

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("Connected stores: 2"))
        #expect(report.contains("All connected stores:"))
        #expect(report.contains("https://alpha.example.com: Plan: business-bundle Jetpack: installed=true connected=true"))
        #expect(report.contains("https://beta.example.com: Plan: unknown Jetpack: installed=false connected=false"))
        #expect(!report.contains("https://blog.example.com"))
    }

    /// `defaultAccount` exists only for WPCom logins. A merchant authenticated with site credentials or an
    /// application password has none, and their report must not claim they are not logged in.
    @Test func a_login_without_a_wpcom_account_is_not_reported_as_logged_out() async {
        // Given
        sessionManager.defaultCredentials = .applicationPassword(username: "merchant",
                                                                 password: "secret",
                                                                 siteAddress: "https://store.example.com")

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("WPCom user ID: N/A (no WPCom account)"))
        #expect(!report.contains("not logged in"))
    }

    /// The remaining `defaultAccount == nil` state: WPCom credentials whose account object has not synced yet,
    /// which is neither "no WPCom account" nor "not logged in".
    @Test func a_wpcom_login_without_a_synced_account_is_reported_as_unknown() async {
        // Given
        sessionManager.defaultCredentials = .wpcom(username: "merchant",
                                                   authToken: "token",
                                                   siteAddress: "https://store.example.com")

        // When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report.contains("WPCom user ID: unknown (WPCom login, account not synced)"))
    }

    // MARK: - Feature flags

    /// `FeatureFlag.null` exists only so the enum can declare a raw type. The feature flag service answers it
    /// through its `default` branch, so without filtering it the local flag list opens with `null: true`,
    /// which reads as a real feature that is switched on.
    @Test func the_placeholder_feature_flag_case_is_not_reported() async {
        // Given, When
        let report = await makeProvider().generateReport()

        // Then
        #expect(!report.contains("\nnull: "))
        #expect(report.contains("### Local flags"))
    }

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
        // A short timeout so the unanswered-dispatch test exercises the degradation without waiting out the
        // production value.
        MobileStatusReportProvider(systemSnapshot: { .fixture() },
                                   pushNotesManager: pushNotesManager ?? self.pushNotesManager,
                                   stores: stores,
                                   storageManager: storageManager,
                                   featureFlagService: MockFeatureFlagService(),
                                   generalAppSettings: appSettings,
                                   dispatchTimeout: 0.05)
    }

    func insert(sites: [Site]) async {
        await withCheckedContinuation { continuation in
            storageManager.performAndSave({ [storageManager] _ in
                sites.forEach { storageManager.insertSampleSite(readOnlySite: $0) }
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
                                         meteredConnection: "false",
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
