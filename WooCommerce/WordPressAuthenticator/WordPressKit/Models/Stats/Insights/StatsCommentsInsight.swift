public struct StatsCommentsInsight {
    public let topPosts: [StatsTopCommentsPost]
    public let topAuthors: [StatsTopCommentsAuthor]

    public init(topPosts: [StatsTopCommentsPost],
                topAuthors: [StatsTopCommentsAuthor]) {
        self.topPosts = topPosts
        self.topAuthors = topAuthors
    }
}

extension StatsCommentsInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/comments"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let posts = jsonDictionary["posts"] as? [[String: AnyObject]],
            let authors = jsonDictionary["authors"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let topPosts = posts.compactMap { StatsTopCommentsPost(jsonDictionary: $0) }
        let topAuthors = authors.compactMap { StatsTopCommentsAuthor(jsonDictionary: $0) }

        self.topPosts = topPosts
        self.topAuthors = topAuthors
    }

}

public struct StatsTopCommentsAuthor {
    public let name: String
    public let commentCount: Int
    public let iconURL: URL?

    public init(name: String,
                commentCount: Int,
                iconURL: URL?) {
        self.name = name
        self.commentCount = commentCount
        self.iconURL = iconURL
    }
}

public struct StatsTopCommentsPost {
    public let name: String
    public let postID: String
    public let commentCount: Int
    public let postURL: URL?

    public init(name: String,
                postID: String,
                commentCount: Int,
                postURL: URL?) {
        self.name = name
        self.postID = postID
        self.commentCount = commentCount
        self.postURL = postURL
    }
}

private extension StatsTopCommentsAuthor {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let name = jsonDictionary["name"] as? String,
            let avatar = jsonDictionary["gravatar"] as? String,
            let comments = jsonDictionary["comments"] as? String,
            let commentCount = Int(comments)
            else {
                return nil
        }

        self.init(name: name, avatar: avatar, commentCount: commentCount)
    }

    init?(name: String, avatar: String, commentCount: Int) {
        let url: URL?

        if var components = URLComponents(string: avatar) {
            components.query = "d=mm&s=60" // to get a properly-sized avatar.
            url = components.url
        } else {
            url = nil
        }

        self.name = name
        self.commentCount = commentCount
        self.iconURL = url
    }
}

private extension StatsTopCommentsPost {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let name = jsonDictionary["name"] as? String,
            let postID = jsonDictionary["id"] as? String,
            let commentString = jsonDictionary["comments"] as? String,
            let commentCount = Int(commentString),
            let postURL = jsonDictionary["link"] as? String
            else {
                return nil
        }

        self.init(name: name,
                  postID: postID,
                  commentCount: commentCount,
                  postURL: URL(string: postURL))
    }
}
