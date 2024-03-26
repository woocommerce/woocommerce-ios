public struct StatsPublicizeInsight {
    public let publicizeServices: [StatsPublicizeService]

    public init(publicizeServices: [StatsPublicizeService]) {
        self.publicizeServices = publicizeServices
    }
}

extension StatsPublicizeInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/publicize"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let subscribers = jsonDictionary["services"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let followers = subscribers.compactMap { StatsPublicizeService(publicizeServiceDictionary: $0) }

        self.publicizeServices = followers
    }

}

public struct StatsPublicizeService {
    public let name: String
    public let followers: Int
    public let iconURL: URL?

    public init(name: String,
                followers: Int,
                iconURL: URL?) {
        self.name = name
        self.followers = followers
        self.iconURL = iconURL
    }
}

private extension StatsPublicizeService {

    init?(publicizeServiceDictionary dictionary: [String: AnyObject]) {
        guard
            let name = dictionary["service"] as? String,
            let followersCount = dictionary["followers"] as? Int else {
                return nil
        }

        self.init(name: name, followers: followersCount)
    }

    init(name: String, followers: Int) {
        let niceName: String
        let icon: URL?

        switch name {
        case "facebook":
            niceName = "Facebook"
            icon = URL(string: "https://secure.gravatar.com/blavatar/2343ec78a04c6ea9d80806345d31fd78?s=60")
        case "twitter":
            niceName = "Twitter"
            icon = URL(string: "https://secure.gravatar.com/blavatar/7905d1c4e12c54933a44d19fcd5f9356?s=60")
        case "tumblr":
            niceName = "Tumblr"
            icon = URL(string: "https://secure.gravatar.com/blavatar/84314f01e87cb656ba5f382d22d85134?s=60")
        case "google_plus":
            niceName = "Google+"
            icon = URL(string: "https://secure.gravatar.com/blavatar/4a4788c1dfc396b1f86355b274cc26b3?s=60")
        case "linkedin":
            niceName = "LinkedIn"
            icon = URL(string: "https://secure.gravatar.com/blavatar/f54db463750940e0e7f7630fe327845e?s=60")
        case "path":
            niceName = "path"
            icon = URL(string: "https://secure.gravatar.com/blavatar/3a03c8ce5bf1271fb3760bb6e79b02c1?s=60")
        default:
            niceName = name
            icon = nil
        }

        self.name = niceName
        self.followers = followers
        self.iconURL = icon
    }
}
