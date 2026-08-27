import Experiments
import Foundation
import os
import WordPressShared
import Yosemite
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
    private let onboardingStateCache: CardPresentPaymentOnboardingStateCache
    private let posEligibilityService: POSEligibilityServiceProtocol

    /// `nil` when the POS database has not been opened this session. The report does not open it: spinning up a
    /// database to describe it would change what is being described.
    private let posCatalogSettingsService: POSCatalogSettingsServiceProtocol?
    private let featureFlagService: FeatureFlagService
    private let generalAppSettings: GeneralAppSettingsStorage

    /// How long `awaitedDispatch` waits before an unanswered dispatch degrades to its fallback. Injectable so
    /// tests can exercise the degradation without waiting out the production value.
    private let dispatchTimeout: TimeInterval

    nonisolated init(systemSnapshot: @escaping () async -> MobileStatusReportSystemSnapshot = { await .current() },
                     pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     onboardingStateCache: CardPresentPaymentOnboardingStateCache = .shared,
                     posEligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
                     posCatalogSettingsService: POSCatalogSettingsServiceProtocol?
                        = MobileStatusReportProvider.makeCatalogSettingsService(),
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     generalAppSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
                     dispatchTimeout: TimeInterval = 1) {
        self.systemSnapshot = systemSnapshot
        self.pushNotesManager = pushNotesManager
        self.stores = stores
        self.storageManager = storageManager
        self.onboardingStateCache = onboardingStateCache
        self.posEligibilityService = posEligibilityService
        self.posCatalogSettingsService = posCatalogSettingsService
        self.featureFlagService = featureFlagService
        self.generalAppSettings = generalAppSettings
        self.dispatchTimeout = dispatchTimeout
    }

    nonisolated private static func makeCatalogSettingsService() -> POSCatalogSettingsServiceProtocol? {
        ServiceLocator.initializedGRDBManager.map { POSCatalogSettingsService(grdbManager: $0) }
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

        // Everything above describes the whole app on this device, everything below only the named store. The
        // band says so once — the same format and position the Android report uses, so a ticket from either
        // platform reads the same way, and a report with no store ends here as Android's does.
        let site = stores.sessionManager.defaultSite
        report += ["", site.map { "# Selected store: \(storeLabel($0))" } ?? Constants.noStoreHeading]

        if let site {
            report += await section("## Store Details") { await self.storeDetailsSection(site) }
            report += await section("## Store Notifications") { self.storeNotificationsSection(site) }
            report += await section("## Payments") { await self.paymentsSection(site) }
            report += await section("## Point of Sale") { await self.pointOfSaleSection(site) }
        }

        return report.joined(separator: "\n")
    }

    private func storeLabel(_ site: Site) -> String {
        site.url.nonEmptyString() ?? site.name.nonEmptyString() ?? "site ID \(site.siteID)"
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

    func storeDetailsSection(_ site: Site) async -> [String] {
        [
            // Blog ID is absent for every application-password store — exactly the population that files login
            // tickets — while Store ID is absent until the first successful system status fetch. One being unset
            // is normal; both being unset points at a store the app has never talked to successfully.
            entry("Blog ID", blogID(site)),
            entry("Store ID", await storeID(site)),
            entry("Auth method", authMethod()),
            entry("Jetpack", "installed=\(site.isJetpackThePluginInstalled) " +
                  "connected=\(site.isJetpackConnected) CP=\(site.isJetpackCPConnected)"),
            entry("Plan", site.plan.nonEmptyString() ?? Constants.unknown),
            entry("Woo core version", wooCoreVersion(siteID: site.siteID) ?? Constants.unknown)
        ]
    }

    /// The bare status. Why it is what it is depends on the token, the permission, a remote flag and the Woo
    /// version, all of which the report already carries — deriving a cause would be a second copy of the
    /// registration rules that starts stating confident nonsense as soon as the two drift.
    func storeNotificationsSection(_ site: Site) -> [String] {
        [entry("Push registration", pushRegistration(siteID: site.siteID))]
    }

    func paymentsSection(_ site: Site) async -> [String] {
        let plugins = sitePlugins(siteID: site.siteID)
        // An empty cache means nothing has fetched this store's plugin list yet, which would send triage the
        // opposite way from "not installed".
        let installState = plugins.isEmpty ?
            [entry("Payment plugins", "unknown (none cached for this store)")] :
            CardPresentPaymentsPlugin.allCases.map { entry(reportName(of: $0), state(of: $0, in: plugins)) }

        return installState + (await inPersonPayments(site, plugins: plugins))
    }

    /// Why POS is hidden or unlaunchable is deliberately not computed: the checks that decide it write these
    /// values as a side effect of evaluating, and a status report must not change what it reports. They log the
    /// reason, and that log is on the same ticket.
    func pointOfSaleSection(_ site: Site) async -> [String] {
        let tabVisible = posEligibilityService.loadCachedPOSTabVisibility(siteID: site.siteID)
        let launchable = posEligibilityService.loadLastKnownPOSEligibility(siteID: site.siteID)
        var entries = [entry("POS tab visible", tabVisible.map(String.init) ?? Constants.notEvaluated),
                       entry("POS launchable", launchable.map(String.init) ?? Constants.notEvaluated),
                       entry("Catalog strategy", await catalogStrategy(siteID: site.siteID)),
                       entry("POS last opened", await posLastOpened(siteID: site.siteID))]
        entries += await localCatalog(siteID: site.siteID)
        entries += [entry("Catalog file blocked", await catalogFileBlocked(siteID: site.siteID)),
                    entry("Full sync on cellular allowed", await fullSyncOnCellularAllowed(siteID: site.siteID))]

        guard tabVisible == false || launchable == false else {
            return entries
        }
        return entries + [Constants.posReasonHint]
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

    /// Counts sit alongside the timestamps because a catalog that has synced but holds no products is a different
    /// problem from one that has never synced.
    func localCatalog(siteID: Int64) async -> [String] {
        guard let posCatalogSettingsService else {
            return [entry("Local catalog", "\(Constants.notEvaluated) (the POS catalog database has not been opened since launch)")]
        }

        do {
            let info = try await posCatalogSettingsService.loadCatalogInfo(for: siteID)
            return [entry("Local catalog products", String(info.productCount)),
                    entry("Local catalog variations", String(info.variationCount)),
                    entry("Local catalog full sync", info.lastFullSyncDate?.iso8601String ?? "never"),
                    entry("Local catalog incremental sync", info.lastIncrementalSyncDate?.iso8601String ?? "never")]
        } catch {
            // Confined to these rows, matching the Android report's per-field degradation: the database read is
            // the section's most failure-prone lookup, and the eligibility rows around it are still worth having.
            DDLogError("⛔️ MobileStatusReportProvider: reading the POS catalog failed: \(error)")
            return [entry("Local catalog products", Constants.unknown),
                    entry("Local catalog variations", Constants.unknown),
                    entry("Local catalog full sync", Constants.unknown),
                    entry("Local catalog incremental sync", Constants.unknown)]
        }
    }

    /// The strategy as POS last decided it — the live check refreshes on a cache miss, which can fetch, so only
    /// the cached decision is read. `not evaluated` means POS has not made the decision since launch.
    func catalogStrategy(siteID: Int64) async -> String {
        guard let checker = stores.posCatalogEligibilityChecker else {
            return Constants.notEvaluated
        }
        switch await checker.cachedCatalogEligibility(for: siteID) {
        case .eligible:
            return "local catalog"
        case .ineligible:
            // `remote` and not `remote API`: the Android report calls the same strategy `remote`, and the value
            // should grep the same across both platforms' tickets.
            return "remote"
        case nil:
            return Constants.notEvaluated
        }
    }

    func posLastOpened(siteID: Int64) async -> String {
        let date = await awaitedDispatch(fallback: Date?.none) { completion in
            AppSettingsAction.getPOSLastOpenedDate(siteID: siteID, onCompletion: completion)
        }
        return date?.iso8601String ?? "never"
    }

    /// Recorded when a catalog file sync fails because the host blocked the file, cleared when it succeeds
    /// again. `true` explains a store that keeps falling back to the slower paginated sync.
    func catalogFileBlocked(siteID: Int64) async -> String {
        let blocked = await awaitedDispatch(fallback: false) { completion in
            AppSettingsAction.getPOSCatalogFileBlockedByHost(siteID: siteID, onCompletion: completion)
        }
        return String(blocked)
    }

    func fullSyncOnCellularAllowed(siteID: Int64) async -> String {
        let allowed = await awaitedDispatch(fallback: false) { completion in
            AppSettingsAction.getPOSLocalCatalogCellularDataAllowed(siteID: siteID, onCompletion: completion)
        }
        return String(allowed)
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

    /// The names the Android report uses for the same plugins, so a Happiness Engineer can grep tickets from
    /// both platforms with one term. `pluginName` is not reused: it labels UI, and the Stripe one differs.
    func reportName(of plugin: CardPresentPaymentsPlugin) -> String {
        switch plugin {
        case .wcPay:
            return "WooPayments"
        case .stripe:
            return "Stripe extension"
        }
    }

    func state(of plugin: CardPresentPaymentsPlugin, in plugins: [SitePlugin]) -> String {
        guard let installed = plugins.first(where: { $0.plugin == plugin.fileNameWithPathExtension }) else {
            return "not installed"
        }
        let state = installed.status == .inactive ? "installed, not active" : "active"
        return "\(state) \(installed.version.nonEmptyString() ?? Constants.unknown)"
    }

    /// Install state alone cannot say which gateway drives in-person payments when both plugins are present. Read
    /// from the stored preference rather than the onboarding use case, which falls back to a network fetch.
    func inPersonPayments(_ site: Site, plugins: [SitePlugin]) async -> [String] {
        let gatewayID = await awaitedDispatch(fallback: String?.none) { completion in
            AppSettingsAction.getPreferredInPersonPaymentGateway(siteID: site.siteID, onCompletion: completion)
        }

        let gateway = gatewayID
            .flatMap { CardPresentPaymentsPlugin.with(gatewayID: $0) }
            .map { plugin in
                let version = plugins.first { $0.plugin == plugin.fileNameWithPathExtension }?.version.nonEmptyString()
                return "\(reportName(of: plugin)) \(version ?? Constants.unknown)"
            }

        return [entry("In-person payments plugin", gateway ?? Constants.notSet),
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
        site.siteID == Constants.applicationPasswordSiteIDPlaceholder ?
            "\(Constants.notSet) (stores connected with application passwords do not have one)" : String(site.siteID)
    }

    func storeID(_ site: Site) async -> String {
        let storedID = await awaitedDispatch(fallback: String?.none) { completion in
            AppSettingsAction.getStoreID(siteID: site.siteID, onCompletion: completion)
        }
        return storedID?.nonEmptyString() ?? "\(Constants.notSet) (no store system status has been fetched yet)"
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
        sitePlugins(siteID: siteID).first { $0.plugin == "woocommerce/woocommerce" }?.version.nonEmptyString()
    }

    func sitePlugins(siteID: Int64) -> [SitePlugin] {
        fetched(ResultsController<StorageSitePlugin>(storageManager: storageManager,
                                                     matching: NSPredicate(format: "siteID == %lld", siteID),
                                                     sortedBy: []))
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
    func awaitedDispatch<Value: Sendable>(fallback: Value,
                                          _ makeAction: (@escaping @Sendable (Value) -> Void) -> Action) async -> Value {
        await withCheckedContinuation { continuation in
            // The completion and the timeout race to resume, and a store is free to answer from any thread, so
            // the flag deciding which of them wins is held under a lock rather than hopped onto one queue.
            let hasResumed = OSAllocatedUnfairLock(initialState: false)
            let resumeOnce: @Sendable (Value) -> Void = { value in
                let isFirstToResume = hasResumed.withLock { resumed -> Bool in
                    guard !resumed else {
                        return false
                    }
                    resumed = true
                    return true
                }
                guard isFirstToResume else { return }
                continuation.resume(returning: value)
            }
            stores.dispatch(makeAction(resumeOnce))
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

        static let noStoreHeading = "# No store selected"
        static let sectionUnavailable = "Info not found"
        static let unknown = "unknown"
        static let notSet = "not set"
        static let notEvaluated = "not evaluated"

        /// Sites connected with application passwords have no real blog ID, so the app stores this in its place.
        static let applicationPasswordSiteIDPlaceholder: Int64 = -1

        /// The quoted strings are the literal prefixes `POSTabVisibilityChecker` and `POSTabEligibilityChecker`
        /// log with — keep the three in step.
        static let posReasonHint = "Reason is logged - search application_log.txt for " +
            "\"POS tab not visible\" or \"POS cannot be launched\""
    }
}

private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
