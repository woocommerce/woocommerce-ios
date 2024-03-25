public struct StatsTodayInsight {
    public let viewsCount: Int
    public let visitorsCount: Int
    public let likesCount: Int
    public let commentsCount: Int

    public init(viewsCount: Int,
                visitorsCount: Int,
                likesCount: Int,
                commentsCount: Int) {
        self.viewsCount = viewsCount
        self.visitorsCount = visitorsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
    }
}

extension StatsTodayInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/summary"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        self.visitorsCount = jsonDictionary["visitors"] as? Int ?? 0
        self.viewsCount = jsonDictionary["views"] as? Int ?? 0
        self.likesCount = jsonDictionary["likes"] as? Int ?? 0
        self.commentsCount = jsonDictionary["comments"] as? Int ?? 0
    }
}
