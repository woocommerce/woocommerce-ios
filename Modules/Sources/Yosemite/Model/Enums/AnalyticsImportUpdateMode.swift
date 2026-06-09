import Foundation

/// How WooCommerce Analytics imports new data.
///
/// Backed by the `woocommerce_analytics_scheduled_import` site setting.
public enum AnalyticsImportUpdateMode: String, CaseIterable, Sendable {
    /// Automatically update analytics data every 12 hours.
    case scheduled = "yes"
    /// Update analytics data as soon as new data becomes available.
    case immediate = "no"

    public init?(backendValue: String) {
        switch backendValue {
        case Self.scheduled.rawValue:
            self = .scheduled
        case Self.immediate.rawValue, "":
            self = .immediate
        default:
            return nil
        }
    }
}
