public struct StatsPostingStreakInsight {
    public let currentStreakStart: Date
    public let currentStreakEnd: Date
    public let currentStreakLength: Int
    public let longestStreakStart: Date
    public let longestStreakEnd: Date
    public let longestStreakLength: Int

    public let postingEvents: [PostingStreakEvent]

    public init(currentStreakStart: Date,
                currentStreakEnd: Date,
                currentStreakLength: Int,
                longestStreakStart: Date,
                longestStreakEnd: Date,
                longestStreakLength: Int,
                postingEvents: [PostingStreakEvent]) {
        self.currentStreakStart = currentStreakStart
        self.currentStreakEnd = currentStreakEnd
        self.currentStreakLength = currentStreakLength

        self.longestStreakStart = longestStreakStart
        self.longestStreakEnd = longestStreakEnd
        self.longestStreakLength = longestStreakLength

        self.postingEvents = postingEvents
    }
}

public struct PostingStreakEvent {
    public let date: Date
    public let postCount: Int

    public init(date: Date, postCount: Int) {
        self.date = date
        self.postCount = postCount
    }
}

extension StatsPostingStreakInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/streak"
    }

    // Some heavy-traffic sites can have A LOT of posts and the default query parameters wouldn't
    // return all the relevant streak data, so we manualy override the `max` and `startDate``/endDate`
    // parameters to hopefully get all.
    public static var queryProperties: [String: String] {
        let today = Date()

        let numberOfDaysInCurrentMonth = Calendar.autoupdatingCurrent.range(of: .day, in: .month, for: today)

        guard
            let firstDayIndex = numberOfDaysInCurrentMonth?.first,
            let lastDayIndex = numberOfDaysInCurrentMonth?.last,
            let lastDayOfMonth = Calendar.autoupdatingCurrent.date(bySetting: .day, value: lastDayIndex, of: today),
            let firstDayOfMonth = Calendar.autoupdatingCurrent.date(bySetting: .day, value: firstDayIndex, of: today),
            let yearAgo = Calendar.autoupdatingCurrent.date(byAdding: .year, value: -1, to: firstDayOfMonth)
            else {
                return [:]
        }

        let firstDayString = self.dateFormatter.string(from: yearAgo)
        let lastDayString = self.dateFormatter.string(from: lastDayOfMonth)

        return ["startDate": "\(firstDayString)",
                "endDate": "\(lastDayString)",
                "max": "5000"]
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let postsData = jsonDictionary["data"] as? [String: AnyObject],
            let streaks = jsonDictionary["streak"] as? [String: AnyObject],
            let longestData = streaks["long"] as? [String: AnyObject],
            let currentData = streaks["current"] as? [String: AnyObject],
            let currentStart = currentData["start"] as? String,
            let currentStartDate = StatsPostingStreakInsight.dateFormatter.date(from: currentStart),
            let currentEnd = currentData["end"] as? String,
            let currentEndDate = StatsPostingStreakInsight.dateFormatter.date(from: currentEnd),
            let currentLength = currentData["length"] as? Int
            else {
                return nil
        }

        let postingDates = postsData.keys
            .compactMap { Double($0) }
            .map { Date(timeIntervalSince1970: $0) }
            .map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }

        let countedPosts = NSCountedSet(array: postingDates)

        let postingEvents = countedPosts.map {
            PostingStreakEvent(date: $0 as! Date, postCount: countedPosts.count(for: $0))
        }

        self.postingEvents = postingEvents
        self.currentStreakStart = currentStartDate
        self.currentStreakEnd = currentEndDate
        self.currentStreakLength = currentLength

        // If there is no longest streak, use the current.
        if let longestStart = longestData["start"] as? String,
            let longestStartDate = StatsPostingStreakInsight.dateFormatter.date(from: longestStart),
            let longestEnd = longestData["end"] as? String,
            let longestEndDate = StatsPostingStreakInsight.dateFormatter.date(from: longestEnd),
            let longestLength = longestData["length"] as? Int {
            self.longestStreakStart = longestStartDate
            self.longestStreakEnd = longestEndDate
            self.longestStreakLength = longestLength
        } else {
            self.longestStreakStart = currentStartDate
            self.longestStreakEnd = currentEndDate
            self.longestStreakLength = currentLength
        }
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

}
