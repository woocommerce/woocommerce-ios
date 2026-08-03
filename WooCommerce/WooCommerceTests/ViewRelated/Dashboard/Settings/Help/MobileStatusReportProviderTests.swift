import Testing
import Foundation
import Networking
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

/// The report is a text artifact, so most of it is pinned by comparing the whole thing: that catches an omitted
/// field and a lost section in one assertion, which per-field tests do not.
///
/// The Feature Flags body is redacted from those comparisons — it enumerates `FeatureFlag.allCases`, so an
/// inline expectation would fail on every unrelated PR that adds a flag. It has its own tests below.
///
/// Serialized because `SessionManager.testingInstance` is backed by a shared `UserDefaults` suite: every test
/// here sets a selected store, and in parallel they overwrite each other's.
@MainActor
@Suite(.serialized)
struct MobileStatusReportProviderTests {

    private let sessionManager: SessionManager
    private let stores: MockStoresManager
    private let storageManager: MockStorageManager

    init() {
        sessionManager = SessionManager.testingInstance
        stores = MockStoresManager(sessionManager: sessionManager)
        storageManager = MockStorageManager()
        sessionManager.defaultSite = nil
        sessionManager.defaultAccount = nil
        sessionManager.defaultCredentials = nil
    }

    @Test func report_carries_every_section() async {
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
}

// MARK: - Helpers

private extension MobileStatusReportProviderTests {

    func makeProvider(pushNotesManager: PushNotesManager = MockPushNotificationsManager()) -> MobileStatusReportProvider {
        MobileStatusReportProvider(systemSnapshot: { .fixture() },
                                   pushNotesManager: pushNotesManager,
                                   stores: stores,
                                   storageManager: storageManager,
                                   featureFlagService: MockFeatureFlagService())
    }

    /// Replaces the bodies of the sections that enumerate every known flag and beta toggle, so an unrelated
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
