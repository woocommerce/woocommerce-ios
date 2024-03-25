public struct StatsLastPostInsight {
    public let title: String
    public let url: URL
    public let publishedDate: Date
    public let likesCount: Int
    public let commentsCount: Int
    public let viewsCount: Int
    public let postID: Int
    public let featuredImageURL: URL?

    public init(title: String,
                url: URL,
                publishedDate: Date,
                likesCount: Int,
                commentsCount: Int,
                viewsCount: Int,
                postID: Int,
                featuredImageURL: URL?) {
        self.title = title
        self.url = url
        self.publishedDate = publishedDate
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.viewsCount = viewsCount
        self.postID = postID
        self.featuredImageURL = featuredImageURL
    }
}

extension StatsLastPostInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static func queryProperties(with maxCount: Int) -> [String: String] {
        return ["order_by": "date",
                "number": "1",
                "type": "post",
                "fields": "ID, title, URL, discussion, like_count, date, featured_image"]
    }

    public static var pathComponent: String {
        return "posts/"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        fatalError("This shouldn't be ever called, instead init?(jsonDictionary:_ views:_) be called instead.")
    }

    // MARK: -

    private static let dateFormatter = ISO8601DateFormatter()

    public init?(jsonDictionary: [String: AnyObject], views: Int) {

        guard
            let title = jsonDictionary["title"] as? String,
            let dateString = jsonDictionary["date"] as? String,
            let date = StatsLastPostInsight.dateFormatter.date(from: dateString),
            let urlString = jsonDictionary["URL"] as? String,
            let url = URL(string: urlString),
            let likesCount = jsonDictionary["like_count"] as? Int,
            let postID = jsonDictionary["ID"] as? Int,
            let discussionDict = jsonDictionary["discussion"] as? [String: Any],
            let commentsCount = discussionDict["comment_count"] as? Int
            else {
                return nil
        }

        self.title = title.trimmingCharacters(in: CharacterSet.whitespaces).stringByDecodingXMLCharacters()
        self.url = url
        self.publishedDate = date
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.viewsCount = views
        self.postID = postID

        if let featuredImage = jsonDictionary["featured_image"] as? String,
           let featuredURL = URL(string: featuredImage) {
            self.featuredImageURL = featuredURL
        } else {
            self.featuredImageURL = nil
        }
    }
}
