public struct StatsEmailFollowersInsight {
    public let emailFollowersCount: Int
    public let topEmailFollowers: [StatsFollower]

    public init(emailFollowersCount: Int,
                topEmailFollowers: [StatsFollower]) {
        self.emailFollowersCount = emailFollowersCount
        self.topEmailFollowers = topEmailFollowers
    }
}

extension StatsEmailFollowersInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static func queryProperties(with maxCount: Int) -> [String: String] {
        return ["type": "email",
                "max": String(maxCount)]
    }

    public static var pathComponent: String {
        return "stats/followers"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let subscribersCount = jsonDictionary["total_email"] as? Int,
            let subscribers = jsonDictionary["subscribers"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let followers = subscribers.compactMap { StatsFollower(jsonDictionary: $0) }

        self.emailFollowersCount = subscribersCount
        self.topEmailFollowers = followers
    }

}
