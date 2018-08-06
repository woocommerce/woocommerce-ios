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

    public var views: Int {
        return payload.fetchIntValue(for: FieldNames.views)
    }

    public var visitors: Int {
        return payload.fetchIntValue(for: FieldNames.visitors)
    }

    public var likes: Int {
        return payload.fetchIntValue(for: FieldNames.likes)
    }

    public var reblogs: Int {
        return payload.fetchIntValue(for: FieldNames.reblogs)
    }

    public var comments: Int {
        return payload.fetchIntValue(for: FieldNames.comments)
    }

    public var posts: Int {
        return payload.fetchIntValue(for: FieldNames.posts)
    }
}


// MARK: - Comparable Conformance
//
extension SiteVisitStatsItem: Comparable {
    public static func == (lhs: SiteVisitStatsItem, rhs: SiteVisitStatsItem) -> Bool {
        return lhs.period == rhs.period &&
            lhs.views == rhs.views &&
            lhs.visitors == rhs.visitors &&
            lhs.likes == rhs.likes &&
            lhs.reblogs == rhs.reblogs &&
            lhs.comments == rhs.comments &&
            lhs.posts == rhs.posts
    }

    public static func < (lhs: SiteVisitStatsItem, rhs: SiteVisitStatsItem) -> Bool {
        return lhs.period < rhs.period ||
            (lhs.period == rhs.period && lhs.views < rhs.views) ||
            (lhs.period == rhs.period && lhs.views == rhs.views && lhs.likes < rhs.likes)
    }
}

// MARK: - Constants!
//
private extension SiteVisitStatsItem {

    /// Defines all of the possbile fields for a SiteVisitStatsItem.
    ///
    enum FieldNames: String {
        case period = "period"
        case views = "views"
        case visitors = "visitors"
        case likes = "likes"
        case reblogs = "reblogs"
        case comments = "comments"
        case posts = "posts"
    }
}
