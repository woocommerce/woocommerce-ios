import Foundation

/// Issue types that users can select when starting a support chat from Help & Support.
///
enum SupportIssueType: String, CaseIterable {
    case loadingOrders
    case loadingProducts
    case loadingAnalytics
    case receivingNotifications
    case other

    /// The diagnostic tests to run for this issue type.
    /// Returns nil for `.other` (no diagnostics needed).
    ///
    var testsToRun: [SupportDiagnosticsService.Test]? {
        switch self {
        case .loadingOrders:
            return [.internetConnection, .site, .siteOrders]
        case .loadingProducts:
            return [.internetConnection, .site, .loadingProducts]
        case .loadingAnalytics:
            return [.internetConnection, .site, .analyticsSetting]
        case .receivingNotifications:
            return [.internetConnection, .site, .notifications]
        case .other:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .loadingOrders:
            return Localization.loadingOrders
        case .loadingProducts:
            return Localization.loadingProducts
        case .loadingAnalytics:
            return Localization.loadingAnalytics
        case .receivingNotifications:
            return Localization.receivingNotifications
        case .other:
            return Localization.other
        }
    }
}

// MARK: - Localization

private extension SupportIssueType {
    enum Localization {
        static let loadingOrders = NSLocalizedString(
            "supportIssueType.loadingOrders",
            value: "Loading orders",
            comment: "Support issue type for problems loading orders"
        )
        static let loadingProducts = NSLocalizedString(
            "supportIssueType.loadingProducts",
            value: "Loading products",
            comment: "Support issue type for problems loading products"
        )
        static let loadingAnalytics = NSLocalizedString(
            "supportIssueType.loadingAnalytics",
            value: "Loading analytics",
            comment: "Support issue type for problems loading analytics"
        )
        static let receivingNotifications = NSLocalizedString(
            "supportIssueType.receivingNotifications",
            value: "Receiving push notifications",
            comment: "Support issue type for problems receiving push notifications"
        )
        static let other = NSLocalizedString(
            "supportIssueType.other",
            value: "Other",
            comment: "Support issue type for other problems not listed"
        )
    }
}
