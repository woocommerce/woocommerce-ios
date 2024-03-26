public struct StatsTagsAndCategoriesInsight {
    public let topTagsAndCategories: [StatsTagAndCategory]

    public init(topTagsAndCategories: [StatsTagAndCategory]) {
        self.topTagsAndCategories = topTagsAndCategories
    }
}

extension StatsTagsAndCategoriesInsight: StatsInsightData {
    public static var pathComponent: String {
        return "stats/tags"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        guard
            let outerTags = jsonDictionary["tags"] as? [[String: AnyObject]]
            // The shape of the API response here leaves... something to be desired.
            else {
                return nil
        }

        let tags = outerTags.compactMap { StatsTagAndCategory(tagsGroup: $0)}

        self.topTagsAndCategories = tags
    }
}

public struct StatsTagAndCategory {

    public enum Kind {
        case tag
        case category
        case folder
    }

    public let name: String
    public let kind: Kind
    public let url: URL?
    public let viewsCount: Int?
    public let children: [StatsTagAndCategory]

    public init(name: String, kind: Kind, url: URL?, viewsCount: Int?, children: [StatsTagAndCategory]) {
        self.name = name
        self.kind = kind
        self.url = url
        self.viewsCount = viewsCount
        self.children = children
    }

}

extension StatsTagAndCategory {
    init?(tagsGroup: [String: AnyObject]) {
        guard
            let innerTags = tagsGroup["tags"] as? [[String: AnyObject]]
            else {
                return nil
        }

        // This gets kinda complicated. The API collects some tags/categories
        // into groups, and we have to handle that.
        if innerTags.count == 1 {
            let tag = innerTags.first!
            let views = tagsGroup["views"] as? Int

            self.init(singleTag: tag, viewsCount: views)
            return
        }

        guard let views = tagsGroup["views"] as? Int else {
            return nil
        }

        let mappedChildren = innerTags.compactMap { StatsTagAndCategory(singleTag: $0) }
        let label = mappedChildren.map { $0.name }.joined(separator: ", ")

        self.init(name: label, kind: .folder, url: nil, viewsCount: views, children: mappedChildren)
    }

    init?(singleTag tag: [String: AnyObject], viewsCount: Int? = 0) {
        guard
            let name = tag["name"] as? String,
            let type = tag["type"] as? String,
            let url = tag["link"] as? String
            else {
                return nil
        }

        let kind: Kind

        switch type {
        case "category":
            kind = .category
        case "tag":
            kind = .tag
        default:
            kind = .category
        }

        self.init(name: name, kind: kind, url: URL(string: url), viewsCount: viewsCount, children: [])
    }
}
