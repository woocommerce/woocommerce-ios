public struct StatsAllAnnualInsight {
    public let allAnnualInsights: [StatsAnnualInsight]

    public init(allAnnualInsights: [StatsAnnualInsight]) {
        self.allAnnualInsights = allAnnualInsights
    }
}

public struct StatsAnnualInsight {
    public let year: Int
    public let totalPostsCount: Int
    public let totalWordsCount: Int
    public let averageWordsCount: Double
    public let totalLikesCount: Int
    public let averageLikesCount: Double
    public let totalCommentsCount: Int
    public let averageCommentsCount: Double
    public let totalImagesCount: Int
    public let averageImagesCount: Double

    public init(year: Int,
                totalPostsCount: Int,
                totalWordsCount: Int,
                averageWordsCount: Double,
                totalLikesCount: Int,
                averageLikesCount: Double,
                totalCommentsCount: Int,
                averageCommentsCount: Double,
                totalImagesCount: Int,
                averageImagesCount: Double) {
        self.year = year
        self.totalPostsCount = totalPostsCount
        self.totalWordsCount = totalWordsCount
        self.averageWordsCount = averageWordsCount
        self.totalLikesCount = totalLikesCount
        self.averageLikesCount = averageLikesCount
        self.totalCommentsCount = totalCommentsCount
        self.averageCommentsCount = averageCommentsCount
        self.totalImagesCount = totalImagesCount
        self.averageImagesCount = averageImagesCount
    }
}

extension StatsAllAnnualInsight: StatsInsightData {
    public static var pathComponent: String {
        return "stats/insights"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard let yearlyInsights = jsonDictionary["years"] as? [[String: AnyObject]] else {
            return nil
        }

        let allAnnualInsights: [StatsAnnualInsight] = yearlyInsights.compactMap {
            guard let yearString = $0["year"] as? String,
                let year = Int(yearString) else {
                    return nil
            }

            return StatsAnnualInsight(year: year,
                                      totalPostsCount: $0["total_posts"] as? Int ?? 0,
                                      totalWordsCount: $0["total_words"] as? Int ?? 0,
                                      averageWordsCount: $0["avg_words"] as? Double ?? 0,
                                      totalLikesCount: $0["total_likes"] as? Int ?? 0,
                                      averageLikesCount: $0["avg_likes"] as? Double ?? 0,
                                      totalCommentsCount: $0["total_comments"] as? Int ?? 0,
                                      averageCommentsCount: $0["avg_comments"] as? Double ?? 0,
                                      totalImagesCount: $0["total_images"] as? Int ?? 0,
                                      averageImagesCount: $0["avg_images"] as? Double ?? 0)
        }

        self.allAnnualInsights = allAnnualInsights
    }
}
