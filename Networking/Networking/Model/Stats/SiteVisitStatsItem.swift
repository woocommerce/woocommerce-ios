import Foundation


/// Represents an single site visit stat for a specific period.
///
public struct SiteVisitStatsItem {
    public let payload: MIContainer

    /// SiteVisitStatsItem struct initializer.
    ///
    public init(fieldNames: [String], rawData: [AnyCodable]) {
        self.payload = MIContainer(data: rawData.map({ $0.value }),
                                   fieldNames: fieldNames)
    }

    // MARK: Computed Properties

    public var period: String {
        return payload.fetchStringValue(for: FieldNames.period)
    }

    public var visitors: Int {
        return payload.fetchIntValue(for: FieldNames.visitors)
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
}

// MARK: - Constants!
//
private extension SiteVisitStatsItem {

    /// Defines all of the possbile fields for a SiteVisitStatsItem.
    ///
    enum FieldNames: String {
        case period = "period"
        case visitors = "visitors"
    }
}
