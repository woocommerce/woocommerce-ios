public struct StatsAllTimesInsight {
    public let postsCount: Int
    public let viewsCount: Int
    public let bestViewsDay: Date
    public let visitorsCount: Int
    public let bestViewsPerDayCount: Int

    public init(postsCount: Int,
                viewsCount: Int,
                bestViewsDay: Date,
                visitorsCount: Int,
                bestViewsPerDayCount: Int) {
        self.postsCount = postsCount
        self.viewsCount = viewsCount
        self.bestViewsDay = bestViewsDay
        self.visitorsCount = visitorsCount
        self.bestViewsPerDayCount = bestViewsPerDayCount
    }
}

extension StatsAllTimesInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let statsDict = jsonDictionary["stats"] as? [String: AnyObject],
            let bestViewsDayString = statsDict["views_best_day"] as? String
            else {
                return nil
        }

        self.postsCount = statsDict["posts"] as? Int ?? 0
        self.bestViewsPerDayCount = statsDict["views_best_day_total"] as? Int ?? 0
        self.visitorsCount = statsDict["visitors"] as? Int ?? 0
        self.viewsCount = statsDict["views"] as? Int ?? 0
        self.bestViewsDay = StatsAllTimesInsight.dateFormatter.date(from: bestViewsDayString) ?? Date()
    }

    // MARK: -
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
