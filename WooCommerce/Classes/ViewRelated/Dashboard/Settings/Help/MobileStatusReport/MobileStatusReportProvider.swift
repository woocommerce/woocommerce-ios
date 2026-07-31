import Foundation

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

    nonisolated init(systemSnapshot: @escaping () async -> MobileStatusReportSystemSnapshot = { await .current() }) {
        self.systemSnapshot = systemSnapshot
    }

    func generateReport() async -> String {
        let system = await systemSnapshot()

        var report = [Constants.heading, Constants.scopeLegend, Constants.fieldReference]

        report += await section("## App", scope: Constants.appWide) { self.appSection(system) }

        return report.joined(separator: "\n")
    }
}

// MARK: - Sections

private extension MobileStatusReportProvider {

    func appSection(_ system: MobileStatusReportSystemSnapshot) -> [String] {
        [entry("Version", system.version),
         entry("Build", system.build)]
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
    }
}
