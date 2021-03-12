import Foundation


/// Represents an single site visit stat for a specific period.
///
public struct SiteVisitStatsItem: GeneratedFakeable {
    public let period: String
    public let visitors: Int

    /// SiteVisitStatsItem struct initializer.
    ///
    public init(period: String, visitors: Int) {
        self.period = period
        self.visitors = visitors
    }
}


// MARK: - Comparable Conformance
//
extension SiteVisitStatsItem: Comparable {
    public static func == (lhs: SiteVisitStatsItem, rhs: SiteVisitStatsItem) -> Bool {
        return lhs.period == rhs.period &&
            lhs.visitors == rhs.visitors
    }

    public static func < (lhs: SiteVisitStatsItem, rhs: SiteVisitStatsItem) -> Bool {
        return lhs.period < rhs.period ||
            (lhs.period == rhs.period && lhs.visitors < rhs.visitors)
    }

    public static func > (lhs: SiteVisitStatsItem, rhs: SiteVisitStatsItem) -> Bool {
        return lhs.period > rhs.period ||
            (lhs.period == rhs.period && lhs.visitors > rhs.visitors)
    }
}
