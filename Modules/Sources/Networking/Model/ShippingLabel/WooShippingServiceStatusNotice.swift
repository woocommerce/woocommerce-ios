import Foundation
import Codegen

/// A carrier service incident reported by the WooCommerce Shipping plugin, e.g. an EasyPost outage.
///
public struct WooShippingServiceStatusNotice: Equatable, GeneratedFakeable, GeneratedCopiable, Sendable {
    public let id: String
    public let severity: WooShippingServiceStatusSeverity
    public let message: String
    public let isDismissible: Bool
    /// Provider status page. Only `http`/`https` URLs with a host are kept.
    public let actionURL: URL?

    public init(id: String,
                severity: WooShippingServiceStatusSeverity,
                message: String,
                isDismissible: Bool,
                actionURL: URL?) {
        self.id = id
        self.severity = severity
        self.message = message
        self.isDismissible = isDismissible
        self.actionURL = actionURL
    }
}

/// Raw values match the API's notice `type`. Ordered from least to most severe.
///
public enum WooShippingServiceStatusSeverity: String, CaseIterable, Comparable, GeneratedFakeable, Sendable {
    case info
    case warning
    case error

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
