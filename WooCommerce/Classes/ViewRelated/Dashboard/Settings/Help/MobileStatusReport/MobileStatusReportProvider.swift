import Foundation
import Yosemite
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

    nonisolated init(systemSnapshot: @escaping () async -> MobileStatusReportSystemSnapshot = { await .current() },
                     pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.systemSnapshot = systemSnapshot
        self.pushNotesManager = pushNotesManager
        self.stores = stores
        self.storageManager = storageManager
    }

    func generateReport(siteAddress: String?) async -> String {
        let system = await systemSnapshot()

        var report = [Constants.heading, Constants.fieldReference]

        report += await section("## App") { self.appSection(system) }
        report += await section("## Device") { self.deviceSection(system) }
        report += await section("## Connectivity") { self.connectivitySection(system) }
        report += await section("## Notifications") { self.notificationsSection(system) }
        report += await section("## Account & Stores") { self.accountSection(siteAddress) }

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
}

// MARK: - Values

private extension MobileStatusReportProvider {

    /// Only stores running WooCommerce: the storage holds every site on the WPCom account, and the Android
    /// report counts Woo stores, so the same merchant must not get two different counts on a cross-platform
    /// ticket.
    func allSites() -> [Site] {
        fetched(ResultsController<StorageSite>(storageManager: storageManager,
                                               matching: NSPredicate(format: "isWooCommerceActive == YES"),
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

        return ["", "All connected stores:"] + sites.map { site in
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
}

extension MobileStatusReportProvider {
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
