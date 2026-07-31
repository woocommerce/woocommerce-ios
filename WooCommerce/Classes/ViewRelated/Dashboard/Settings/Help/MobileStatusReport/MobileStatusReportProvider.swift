import Foundation
import Yosemite
import enum Networking.WooConstants
import protocol Storage.StorageManagerType

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
final class MobileStatusReportProvider {

    private let systemSnapshot: () async -> MobileStatusReportSystemSnapshot
    private let pushNotesManager: PushNotesManager
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let onboardingStateCache: CardPresentPaymentOnboardingStateCache

    nonisolated init(systemSnapshot: @escaping () async -> MobileStatusReportSystemSnapshot = { await .current() },
                     pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     onboardingStateCache: CardPresentPaymentOnboardingStateCache = .shared) {
        self.systemSnapshot = systemSnapshot
        self.pushNotesManager = pushNotesManager
        self.stores = stores
        self.storageManager = storageManager
        self.onboardingStateCache = onboardingStateCache
    }

    /// - Parameter siteAddress: the address the merchant typed into the support form, which can differ from the
    /// selected store when they are contacting us precisely because the app picked up the wrong one.
    func generateReport(siteAddress: String? = nil) async -> String {
        let system = await systemSnapshot()

        let site = stores.sessionManager.defaultSite
        let storeScope = site?.url.nilIfEmpty.map { "(selected store: \($0))" } ?? "(no store selected)"

        var report = [Constants.heading, Constants.scopeLegend, Constants.fieldReference]

        report += await section("## App", scope: Constants.appWide) { self.appSection(system) }
        report += await section("## Device", scope: Constants.appWide) { self.deviceSection(system) }
        report += await section("## Connectivity", scope: Constants.appWide) { self.connectivitySection(system) }
        report += await section("## Notifications", scope: Constants.appWide) { self.notificationsSection(system) }
        report += await section("## Account & Stores", scope: Constants.appWide) { self.accountSection(siteAddress) }
        report += await section("## Store Details", scope: storeScope) { self.storeDetailsSection(site) }
        report += await section("## Store Notifications", scope: storeScope) { self.storeNotificationsSection(site) }
        report += await section("## Payments", scope: storeScope) { self.paymentsSection(site) }

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
         entry("Expensive connection", system.expensiveConnection),
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
        return [entry("WPCom user ID", stores.sessionManager.defaultAccount.map { String($0.userID) } ?? "not logged in"),
                siteAddress?.nilIfEmpty.map { entry("Address given in the form", $0) },
                entry("Connected stores", String(sites.count))].compactMap { $0 } + siteList(sites)
    }

    func storeDetailsSection(_ site: Site?) -> [String] {
        guard let site else {
            return [Constants.noStore]
        }

        return [
            // Blog ID is absent for every application-password store — exactly the population that files login
            // tickets — while Store ID is absent until the first successful system status fetch. One being unset
            // is normal; both being unset points at a store the app has never talked to successfully.
            entry("Blog ID", blogID(site)),
            entry("Store ID", storeID(site)),
            entry("Auth method", authMethod()),
            entry("Jetpack", "installed=\(site.isJetpackThePluginInstalled) " +
                  "connected=\(site.isJetpackConnected) CP=\(site.isJetpackCPConnected)"),
            entry("Plan", site.plan.nilIfEmpty ?? Constants.unknown),
            entry("Woo core version", wooCoreVersion(siteID: site.siteID) ?? Constants.unknown)
        ]
    }

    /// The bare status. Why it is what it is depends on the token, the permission, a remote flag and the Woo
    /// version, all of which the report already carries — deriving a cause would be a second copy of the
    /// registration rules that starts stating confident nonsense as soon as the two drift.
    func storeNotificationsSection(_ site: Site?) -> [String] {
        guard let site else {
            return [Constants.noStore]
        }
        return [entry("Push registration", pushRegistration(siteID: site.siteID))]
    }

    func paymentsSection(_ site: Site?) -> [String] {
        guard let site else {
            return [Constants.noStore]
        }

        let plugins = sitePlugins(siteID: site.siteID)
        // An empty cache means nothing has fetched this store's plugin list yet, which would send triage the
        // opposite way from "not installed".
        let installState = plugins.isEmpty ?
            [entry("Payment plugins", "unknown (none cached for this store)")] :
            CardPresentPaymentsPlugin.allCases.map { entry($0.pluginName, state(of: $0, in: plugins)) }

        return installState + inPersonPayments(site, plugins: plugins)
    }
}

// MARK: - Values

private extension MobileStatusReportProvider {

    func state(of plugin: CardPresentPaymentsPlugin, in plugins: [SitePlugin]) -> String {
        guard let installed = plugins.first(where: { $0.plugin == plugin.fileNameWithPathExtension }) else {
            return "not installed"
        }
        let state = installed.status == .inactive ? "installed, not active" : "active"
        return "\(state) \(installed.version.nilIfEmpty ?? Constants.unknown)"
    }

    /// Install state alone cannot say which gateway drives in-person payments when both plugins are present. Read
    /// from the stored preference rather than the onboarding use case, which falls back to a network fetch.
    func inPersonPayments(_ site: Site, plugins: [SitePlugin]) -> [String] {
        var gatewayID: String?
        stores.dispatch(AppSettingsAction.getPreferredInPersonPaymentGateway(siteID: site.siteID) { gatewayID = $0 })

        let gateway = gatewayID
            .flatMap { CardPresentPaymentsPlugin.with(gatewayID: $0) }
            .map { plugin in
                let version = plugins.first { $0.plugin == plugin.fileNameWithPathExtension }?.version.nilIfEmpty
                return "\(plugin.pluginName) \(version ?? Constants.unknown)"
            }

        return [entry("In-person payments gateway", gateway ?? Constants.notSet),
                // Held in memory only, so absent until the merchant opens a payments screen — the expected value
                // for a ticket about anything else.
                entry("In-person payments onboarding",
                      onboardingStateCache.value?.reasonForAnalytics
                      ?? "\(Constants.notEvaluated) (the merchant has not opened a payments screen since launch)")]
    }

    /// The Woo token is registered per store; the WPCom device registration is account-wide. `REGISTERED_BOTH` is
    /// the usual explanation for duplicate new-order notifications.
    func pushRegistration(siteID: Int64) -> String {
        switch (pushNotesManager.siteIDsRegisteredForWooPNs.contains(siteID),
                pushNotesManager.deviceID?.isNotEmpty == true) {
        case (true, true):
            return "REGISTERED_BOTH"
        case (true, false):
            return "REGISTERED_WOO_ONLY"
        case (false, true):
            return "REGISTERED_WPCOM_ONLY"
        case (false, false):
            return "UNREGISTERED"
        }
    }

    func blogID(_ site: Site) -> String {
        site.siteID == Networking.WooConstants.placeholderSiteID ?
            "\(Constants.notSet) (stores connected with application passwords do not have one)" : String(site.siteID)
    }

    /// `AppSettingsStore` resolves this inline, which is what lets the report stay synchronous here. Were that to
    /// change, an unanswered dispatch would report "not set" for a store that has an ID.
    func storeID(_ site: Site) -> String {
        var storedID: String?
        stores.dispatch(AppSettingsAction.getStoreID(siteID: site.siteID) { storedID = $0 })
        return storedID?.nilIfEmpty ?? "\(Constants.notSet) (no store system status has been fetched yet)"
    }

    /// The credentials say what the app holds, the request mode says how it uses them, and a Jetpack site can be
    /// driven by either.
    func authMethod() -> String {
        switch stores.sessionManager.defaultCredentials {
        case .wpcom:
            return "WPCom"
        case .wporg:
            return "SiteCredentials"
        case .applicationPassword:
            return stores.requestAuthenticationMode == .appPasswordsWithJetpack ?
                "ApplicationPasswordsWithJetpack" : "ApplicationPasswords"
        case .none:
            return "not logged in"
        }
    }

    func wooCoreVersion(siteID: Int64) -> String? {
        sitePlugins(siteID: siteID).first { $0.plugin == "woocommerce/woocommerce" }?.version.nilIfEmpty
    }

    func sitePlugins(siteID: Int64) -> [SitePlugin] {
        fetched(ResultsController<StorageSitePlugin>(storageManager: storageManager,
                                                     matching: NSPredicate(format: "siteID == %lld", siteID),
                                                     sortedBy: []))
    }

    func allSites() -> [Site] {
        fetched(ResultsController<StorageSite>(storageManager: storageManager,
                                               sortedBy: [NSSortDescriptor(key: "name", ascending: true)]))
    }

    func fetched<T>(_ controller: ResultsController<T>) -> [T.ReadOnlyType] {
        try? controller.performFetch()
        return controller.fetchedObjects
    }

    /// Merchants often report a problem on a store other than the selected one. Only the selected store's plugins
    /// have usually been fetched, so these lines carry no plugin versions.
    func siteList(_ sites: [Site]) -> [String] {
        guard sites.isNotEmpty else {
            return []
        }

        return ["", "All connected sites:"] + sites.map { site in
            entry(site.url.nilIfEmpty ?? Constants.unknown,
                  "Plan: \(site.plan.nilIfEmpty ?? Constants.unknown) " +
                  "Jetpack: installed=\(site.isJetpackThePluginInstalled) connected=\(site.isJetpackConnected)")
        }
    }

    /// Enough to compare against server logs, not enough to address the device.
    func redactedToken(_ token: String?) -> String {
        token?.nilIfEmpty.map { "present (…\($0.suffix(6)))" } ?? "missing"
    }
}

// MARK: - Report structure

private extension MobileStatusReportProvider {

    func section(_ heading: String, scope: String, content: () async throws -> [String]) async -> [String] {
        let lines: [String]
        do {
            lines = try await content()
        } catch {
            DDLogError("⛔️ MobileStatusReportProvider: \(heading) unavailable: \(error)")
            lines = [Constants.sectionUnavailable]
        }
        return ["", "\(heading) \(scope)"] + lines
    }

    func entry(_ key: String, _ value: String) -> String {
        "\(key): \(value)"
    }
}

extension MobileStatusReportProvider {
    enum Constants {
        static let heading = "### Mobile Status Report generated via the WooCommerce iOS app ###"

        /// Spelled out in the report rather than left to be inferred: this is read by Happiness Engineers and by
        /// merchants in Help & Support alike.
        static let scopeLegend = "Scopes: \(appWide) values cover the whole app on this device. " +
            "(selected store: ...) values cover only the named store."

        /// Field meanings live in the repository. Inline they would double the length of something attached to
        /// every ticket, for readers who already know the fields.
        static let fieldReference = "Field reference: " +
            "https://github.com/woocommerce/woocommerce-ios/blob/trunk/docs/mobile-status-report.md"

        static let appWide = "(app-wide)"
        static let sectionUnavailable = "Info not found"
        static let unknown = "unknown"
        static let notSet = "not set"
        static let noStore = "Not applicable while no store is selected"
        static let notEvaluated = "not evaluated"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
