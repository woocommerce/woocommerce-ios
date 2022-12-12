import Foundation
import Codegen

/// Represents a single site visit stat for a specific period.
///
public struct SiteVisitStatsItem: Equatable, GeneratedCopiable, GeneratedFakeable {
    public let period: String
    public let visitors: Int
    public let views: Int

    /// SiteVisitStatsItem struct initializer.
    ///
    public init(period: String, visitors: Int, views: Int) {
        self.period = period
        self.visitors = visitors
        self.views = views
    }
}


// MARK: - Comparable Conformance
//
extension SiteVisitStatsItem: Comparable {
    public static func < (lhs: SiteVisitStatsItem, rhs: SiteVisitStatsItem) -> Bool {
        return lhs.period < rhs.period ||
            (lhs.period == rhs.period && lhs.visitors < rhs.visitors) ||
            (lhs.period == rhs.period && lhs.visitors == rhs.visitors && lhs.views < rhs.views)
    }
}
