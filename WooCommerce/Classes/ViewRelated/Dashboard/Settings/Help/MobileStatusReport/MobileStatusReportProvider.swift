import Experiments
import Foundation
import WordPressShared
import Yosemite
import enum Networking.RemoteFeatureFlag
import struct Storage.GeneralAppSettingsStorage
import protocol Storage.StorageManagerType

/// Builds the Mobile Status Report. A protocol so the ticket-creation callers can be tested against a canned
/// report instead of assembling the provider's dependencies.
protocol MobileStatusReportProviding {
    /// - Parameter siteAddress: the address the merchant typed into the support form, which can differ from the
    /// selected store when they are contacting us precisely because the app picked up the wrong one.
    func generateReport(siteAddress: String?) async -> String
}

extension MobileStatusReportProviding {
    func generateReport() async -> String {
        await generateReport(siteAddress: nil)
    }
}

/// Builds the Mobile Status Report attached to support tickets and shown to merchants in Help & Support — the
/// app-level counterpart to the server-side System Status Report, which carries no device or app information and
/// is empty on tickets filed from the login screen.
///
/// Two rules hold for every section:
///
/// - **Nothing here touches the network.** Adding a read that does would put ticket creation behind it and stop
///   Help & Support rendering instantly when logged out.
/// - **A failing lookup degrades to `Info not found` rather than failing the report.** This runs while a merchant
///   is trying to reach support and must never be the reason they cannot.
///
@MainActor
final class MobileStatusReportProvider: MobileStatusReportProviding {

    private let systemSnapshot: () async -> MobileStatusReportSystemSnapshot
    private let pushNotesManager: PushNotesManager
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let featureFlagService: FeatureFlagService
    private let generalAppSettings: GeneralAppSettingsStorage

    /// How long `awaitedDispatch` waits before an unanswered dispatch degrades to its fallback. Injectable so
    /// tests can exercise the degradation without waiting out the production value.
    private let dispatchTimeout: TimeInterval

    nonisolated init(systemSnapshot: @escaping () async -> MobileStatusReportSystemSnapshot = { await .current() },
                     pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     generalAppSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
                     dispatchTimeout: TimeInterval = 1) {
        self.systemSnapshot = systemSnapshot
        self.pushNotesManager = pushNotesManager
        self.stores = stores
        self.storageManager = storageManager
        self.featureFlagService = featureFlagService
        self.generalAppSettings = generalAppSettings
        self.dispatchTimeout = dispatchTimeout
    }

    func generateReport(siteAddress: String?) async -> String {
        let system = await systemSnapshot()

        var report = [Constants.heading, Constants.fieldReference]

        report += await section("## App") { self.appSection(system) }
        report += await section("## Device") { self.deviceSection(system) }
        report += await section("## Connectivity") { self.connectivitySection(system) }
        report += await section("## Notifications") { self.notificationsSection(system) }
        report += await section("## Account & Stores") { self.accountSection(siteAddress) }
        report += await section("## Feature Flags") { await self.featureFlagsSection() }
        report += await section("## Experimental Features") { self.experimentalFeaturesSection() }

        return report.joined(separator: "\n")
    }
}

// MARK: - Sections

private extension MobileStatusReportProvider {

    func appSection(_ system: MobileStatusReportSystemSnapshot) -> [String] {
        [entry("Version", system.version),
         entry("Build", system.build)]
    }

    func deviceSection(_ system: MobileStatusReportSystemSnapshot) -> [String] {
        [entry("Model", system.model),
         entry("OS", system.os),
         entry("Free space", system.freeSpace),
         entry("Screen", system.screen),
         entry("Device locale", system.deviceLocale),
         entry("App language", system.appLanguage)]
    }

    func connectivitySection(_ system: MobileStatusReportSystemSnapshot) -> [String] {
        [entry("Network type", system.networkType),
         entry("Metered connection", system.meteredConnection),
         entry("Low Data Mode", system.lowDataMode)]
    }

    /// Push registration is the one notification value keyed on a single store, so it is reported with that store
    /// rather than among these device-level settings.
    func notificationsSection(_ system: MobileStatusReportSystemSnapshot) -> [String] {
        [entry("APNs environment", system.apnsEnvironment),
         // The raw state, because `provisional` means the app delivers quietly — notifications arrive with no
         // banner and no sound, which a merchant reads as none arriving at all.
         entry("Authorization status", system.authorizationStatus),
         entry("Alerts", system.alerts),
         entry("Sounds", system.sounds),
         entry("Lock screen", system.lockScreen),
         entry("Time-sensitive", system.timeSensitive),
         entry("Scheduled summary", system.scheduledSummary),
         entry("APNs device token", redactedToken(pushNotesManager.deviceToken)),
         // Redacted like the APNs token: the last characters are enough to match against server logs, which is
         // the only reason to report it.
         entry("Woo push token ID", redactedToken(pushNotesManager.wooPushNotificationToken)),
         entry("Background refresh", system.backgroundRefresh),
         entry("Low Power Mode", system.lowPowerMode)]
    }

    func accountSection(_ siteAddress: String?) -> [String] {
        let sites = allSites()
        return [entry("WPCom user ID", wpcomUserID()),
                siteAddress?.nonEmptyString().map { entry("Address given in the form", $0) },
                entry("Connected stores", String(sites.count))].compactMap { $0 } + siteList(sites)
    }

    /// Two independent systems holding different flags, so both are reported and labelled. Every flag is listed,
    /// not only the enabled ones: an absent key would be ambiguous between disabled, renamed and deleted.
    func featureFlagsSection() async -> [String] {
        ["", "### Local flags"] + localFeatureFlags() + ["", "### Remote flags"] + (await remoteFeatureFlags())
    }

    /// `BetaFeature` is the same list the settings screen renders, so a toggle added there appears here — and
    /// the exhaustive switch in `reportName(of:)` then forces it to be given a report label.
    func experimentalFeaturesSection() -> [String] {
        BetaFeature.allCases.map { entry(reportName(of: $0), String(generalAppSettings.betaFeatureEnabled($0))) }
    }
}

// MARK: - Values

private extension MobileStatusReportProvider {

    /// An account exists only for WPCom logins, so its absence alone does not distinguish a merchant using site
    /// credentials or application passwords from one who is not logged in at all — the held credentials do.
    func wpcomUserID() -> String {
        if let account = stores.sessionManager.defaultAccount {
            return String(account.userID)
        }
        switch stores.sessionManager.defaultCredentials {
        case .wpcom:
            return "\(Constants.unknown) (WPCom login, account not synced)"
        case .wporg, .applicationPassword:
            return "N/A (no WPCom account)"
        case .none:
            return "not logged in"
        }
    }

    /// `.null` is skipped: it is a throwaway case that exists only so the enum can declare a raw type, and the
    /// service answers it through the `default` branch, so it would appear as a real flag that is switched on.
    func localFeatureFlags() -> [String] {
        FeatureFlag.allCases.filter { $0 != .null }
            .map { entry(String(describing: $0), String(featureFlagService.isFeatureFlagEnabled($0))) }
    }

    /// What the app is acting on, which is not the same as what is in the cache: an expired cache is not
    /// consulted, so listing it would describe behaviour the app is not exhibiting.
    func remoteFeatureFlags() async -> [String] {
        // The action deliberately does not fetch. A dropped dispatch degrades to nil, the safe reading.
        let values = await awaitedDispatch(fallback: [RemoteFeatureFlag: Bool]?.none) { completion in
            FeatureFlagAction.loadRemoteFeatureFlagsInEffect(completion: completion)
        }

        guard let values else {
            return [entry("Remote values loaded", "false (nothing fetched this session, or the last fetch aged out)")]
        }
        return [entry("Remote values loaded", "true")] + RemoteFeatureFlag.allCases.map { flag in
            entry(String(describing: flag), values[flag].map { "\($0) (remote)" } ?? "not returned by server")
        }
    }

    /// Stable English labels, not `title`: that is localized UI copy, which would put translated keys in a
    /// report Happiness Engineers grep in English. `Product add-ons` and `POS local catalog` are the labels the
    /// Android report uses for its equivalent toggles.
    func reportName(of feature: BetaFeature) -> String {
        switch feature {
        case .viewAddOns:
            return "Product add-ons"
        case .applicationPasswords:
            return "Application passwords"
        case .posLocalCatalog:
            return "POS local catalog"
        }
    }

    /// Only stores running WooCommerce: the storage holds every site on the WPCom account, and the Android
    /// report counts Woo stores, so the same merchant must not get two different counts on a cross-platform
    /// ticket.
    func allSites() -> [Site] {
        fetched(ResultsController<StorageSite>(storageManager: storageManager,
                                               matching: NSPredicate(format: "isWooCommerceActive == YES"),
                                               sortedBy: [NSSortDescriptor(key: "name", ascending: true)]))
    }

    func fetched<T>(_ controller: ResultsController<T>) -> [T.ReadOnlyType] {
        do {
            try controller.performFetch()
        } catch {
            DDLogError("⛔️ MobileStatusReportProvider: fetching \(T.entityName) failed: \(error)")
        }
        return controller.fetchedObjects
    }

    /// Merchants often report a problem on a store other than the selected one. Only the selected store's plugins
    /// have usually been fetched, so these lines carry no plugin versions.
    func siteList(_ sites: [Site]) -> [String] {
        guard sites.isNotEmpty else {
            return []
        }

        return ["", "All connected stores:"] + sites.map { site in
            entry(site.url.nonEmptyString() ?? Constants.unknown,
                  "Plan: \(site.plan.nonEmptyString() ?? Constants.unknown) " +
                  "Jetpack: installed=\(site.isJetpackThePluginInstalled) connected=\(site.isJetpackConnected)")
        }
    }

    /// Enough to compare against server logs, not enough to address the device.
    func redactedToken(_ token: String?) -> String {
        token?.nonEmptyString().map { "present (…\($0.suffix(6)))" } ?? "missing"
    }
}

// MARK: - Report structure

private extension MobileStatusReportProvider {

    func section(_ heading: String, content: () async throws -> [String]) async -> [String] {
        let lines: [String]
        do {
            lines = try await content()
        } catch {
            DDLogError("⛔️ MobileStatusReportProvider: \(heading) unavailable: \(error)")
            lines = [Constants.sectionUnavailable]
        }
        return ["", heading] + lines
    }

    func entry(_ key: String, _ value: String) -> String {
        "\(key): \(value)"
    }

    /// Dispatches an action answered from local state and returns its completion value.
    ///
    /// The await is bounded because a dispatch is not guaranteed an answer: the deauthenticated stores manager
    /// drops actions for stores it does not run (`AppSettingsStore` among them), and no completion ever comes.
    /// After `dispatchTimeout` the value degrades to `fallback` — a field reading "not set" is recoverable, a
    /// report that never finishes while a merchant files a ticket is not.
    func awaitedDispatch<Value>(fallback: Value,
                                _ makeAction: (@escaping (Value) -> Void) -> Action) async -> Value {
        await withCheckedContinuation { continuation in
            var resumed = false
            let resumeOnce: (Value) -> Void = { value in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: value)
            }
            stores.dispatch(makeAction { value in
                // Stores answer these inline on the main queue today; the hop keeps `resumed` main-only if one
                // ever answers from elsewhere.
                DispatchQueue.main.async { resumeOnce(value) }
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + dispatchTimeout) { resumeOnce(fallback) }
        }
    }
}

private extension MobileStatusReportProvider {
    enum Constants {
        static let heading = "### Mobile Status Report generated via the WooCommerce iOS app ###"

        /// Field meanings live in the repository. Inline they would double the length of something attached to
        /// every ticket, for readers who already know the fields.
        static let fieldReference = "Field reference: " +
            "https://github.com/woocommerce/woocommerce-ios/blob/trunk/docs/mobile-status-report.md"

        static let sectionUnavailable = "Info not found"
        static let unknown = "unknown"
    }
}
