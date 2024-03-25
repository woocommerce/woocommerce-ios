public struct StatsAnnualAndMostPopularTimeInsight {

    /// - A `DateComponents` object with one field populated: `weekday`.
    public let mostPopularDayOfWeek: DateComponents
    public let mostPopularDayOfWeekPercentage: Int

    /// - A `DateComponents` object with one field populated: `hour`.
    public let mostPopularHour: DateComponents
    public let mostPopularHourPercentage: Int

    public let annualInsightsYear: Int

    public let annualInsightsTotalPostsCount: Int
    public let annualInsightsTotalWordsCount: Int
    public let annualInsightsAverageWordsCount: Double

    public let annualInsightsTotalLikesCount: Int
    public let annualInsightsAverageLikesCount: Double

    public let annualInsightsTotalCommentsCount: Int
    public let annualInsightsAverageCommentsCount: Double

    public let annualInsightsTotalImagesCount: Int
    public let annualInsightsAverageImagesCount: Double

    public init(mostPopularDayOfWeek: DateComponents,
                mostPopularDayOfWeekPercentage: Int,
                mostPopularHour: DateComponents,
                mostPopularHourPercentage: Int,
                annualInsightsYear: Int,
                annualInsightsTotalPostsCount: Int,
                annualInsightsTotalWordsCount: Int,
                annualInsightsAverageWordsCount: Double,
                annualInsightsTotalLikesCount: Int,
                annualInsightsAverageLikesCount: Double,
                annualInsightsTotalCommentsCount: Int,
                annualInsightsAverageCommentsCount: Double,
                annualInsightsTotalImagesCount: Int,
                annualInsightsAverageImagesCount: Double) {
        self.mostPopularDayOfWeek = mostPopularDayOfWeek
        self.mostPopularDayOfWeekPercentage = mostPopularDayOfWeekPercentage

        self.mostPopularHour = mostPopularHour
        self.mostPopularHourPercentage = mostPopularHourPercentage

        self.annualInsightsYear = annualInsightsYear

        self.annualInsightsTotalPostsCount = annualInsightsTotalPostsCount
        self.annualInsightsTotalWordsCount = annualInsightsTotalWordsCount
        self.annualInsightsAverageWordsCount = annualInsightsAverageWordsCount

        self.annualInsightsTotalLikesCount = annualInsightsTotalLikesCount
        self.annualInsightsAverageLikesCount = annualInsightsAverageLikesCount

        self.annualInsightsTotalCommentsCount = annualInsightsTotalCommentsCount
        self.annualInsightsAverageCommentsCount = annualInsightsAverageCommentsCount

        self.annualInsightsTotalImagesCount = annualInsightsTotalImagesCount
        self.annualInsightsAverageImagesCount = annualInsightsAverageImagesCount
    }
}

extension StatsAnnualAndMostPopularTimeInsight: StatsInsightData {
    public static var pathComponent: String {
        return "stats/insights"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let highestHour = jsonDictionary["highest_hour"] as? Int,
            let highestHourPercentageValue = jsonDictionary["highest_hour_percent"] as? Double,
            let highestDayOfWeek = jsonDictionary["highest_day_of_week"] as? Int,
            let highestDayOfWeekPercentageValue = jsonDictionary["highest_day_percent"] as? Double,
            let yearlyInsights = jsonDictionary["years"] as? [[String: AnyObject]],
            let latestYearlyInsight = yearlyInsights.last,
            let yearString = latestYearlyInsight["year"] as? String,
            let currentYear = Int(yearString)
            else {
                return nil
        }

        let mappedWeekday: ((Int) -> Int) = {
            // iOS Calendar system is `1-based` and uses Sunday as the first day of the week.
            // The data returned from WP.com is `0-based` and uses Monday as the first day of the week.
            // This maps the WP.com data to iOS format.
            return $0 == 6 ? 0 : $0 + 2
        }

        let weekDayComponent = DateComponents(weekday: mappedWeekday(highestDayOfWeek))
        let hourComponents = DateComponents(hour: highestHour)

        self.mostPopularDayOfWeek = weekDayComponent
        self.mostPopularDayOfWeekPercentage = Int(highestDayOfWeekPercentageValue.rounded())
        self.mostPopularHour = hourComponents
        self.mostPopularHourPercentage = Int(highestHourPercentageValue.rounded())

        self.annualInsightsYear = currentYear

        self.annualInsightsTotalPostsCount = latestYearlyInsight["total_posts"] as? Int ?? 0
        self.annualInsightsTotalWordsCount = latestYearlyInsight["total_words"] as? Int ?? 0
        self.annualInsightsAverageWordsCount = latestYearlyInsight["avg_words"] as? Double ?? 0

        self.annualInsightsTotalLikesCount = latestYearlyInsight["total_likes"] as? Int ?? 0
        self.annualInsightsAverageLikesCount = latestYearlyInsight["avg_likes"] as? Double ?? 0

        self.annualInsightsTotalCommentsCount = latestYearlyInsight["total_comments"] as? Int ?? 0
        self.annualInsightsAverageCommentsCount = latestYearlyInsight["avg_comments"] as? Double ?? 0

        self.annualInsightsTotalImagesCount = latestYearlyInsight["total_images"] as? Int ?? 0
        self.annualInsightsAverageImagesCount = latestYearlyInsight["avg_images"] as? Double ?? 0
    }
}
