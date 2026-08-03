import Foundation

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

    nonisolated init(systemSnapshot: @escaping () async -> MobileStatusReportSystemSnapshot = { await .current() }) {
        self.systemSnapshot = systemSnapshot
    }

    func generateReport(siteAddress: String?) async -> String {
        let system = await systemSnapshot()

        var report = [Constants.heading, Constants.fieldReference]

        report += await section("## App") { self.appSection(system) }
        report += await section("## Device") { self.deviceSection(system) }

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
    }
}
