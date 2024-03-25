public struct StatsDotComFollowersInsight {
    public let dotComFollowersCount: Int
    public let topDotComFollowers: [StatsFollower]

    public init (dotComFollowersCount: Int,
                 topDotComFollowers: [StatsFollower]) {
        self.dotComFollowersCount = dotComFollowersCount
        self.topDotComFollowers = topDotComFollowers
    }
}

extension StatsDotComFollowersInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static func queryProperties(with maxCount: Int) -> [String: String] {
        return ["type": "wpcom",
                "max": String(maxCount)]
    }

    public static var pathComponent: String {
        return "stats/followers"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let subscribersCount = jsonDictionary["total_wpcom"] as? Int,
            let subscribers = jsonDictionary["subscribers"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let followers = subscribers.compactMap { StatsFollower(jsonDictionary: $0) }

        self.dotComFollowersCount = subscribersCount
        self.topDotComFollowers = followers
    }

    // MARK: -
    fileprivate static let dateFormatter = ISO8601DateFormatter()
}

public struct StatsFollower {
    public let id: String?
    public let name: String
    public let subscribedDate: Date
    public let avatarURL: URL?

    public init(name: String,
                subscribedDate: Date,
                avatarURL: URL?,
                id: String? = nil) {
        self.name = name
        self.subscribedDate = subscribedDate
        self.avatarURL = avatarURL
        self.id = id
    }
}

extension StatsFollower {

    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let name = jsonDictionary["label"] as? String,
            let avatar = jsonDictionary["avatar"] as? String,
            let dateString = jsonDictionary["date_subscribed"] as? String
            else {
                return nil
        }
        let id = jsonDictionary["ID"] as? String
        self.init(name: name, avatar: avatar, date: dateString, id: id)
    }

    init?(name: String, avatar: String, date: String, id: String? = nil) {
        guard let date = StatsDotComFollowersInsight.dateFormatter.date(from: date) else {
            return nil
        }

        let url: URL?

        if var components = URLComponents(string: avatar) {
            components.query = "d=mm&s=60" // to get a properly-sized avatar.
            url = components.url
        } else {
            url = nil
        }

        self.name = name
        self.subscribedDate = date
        self.avatarURL = url
        self.id = id
    }
}
