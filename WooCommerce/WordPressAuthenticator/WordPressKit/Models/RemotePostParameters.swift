import Foundation

/// The parameters required to create a post or a page.
public struct RemotePostCreateParameters: Equatable {
    public var type: String

    public var status: String
    public var date: Date?
    public var authorID: Int?
    public var title: String?
    public var content: String?
    public var password: String?
    public var excerpt: String?
    public var slug: String?
    public var featuredImageID: Int?

    // Pages
    public var parentPageID: Int?

    // Posts
    public var format: String?
    public var isSticky = false
    public var tags: [String] = []
    public var categoryIDs: [Int] = []

    public init(type: String, status: String) {
        self.type = type
        self.status = status
    }
}

/// Represents a partial update to be applied to a post or a page.
public struct RemotePostUpdateParameters: Equatable {
    public var ifNotModifiedSince: Date?

    public var status: String?
    public var date: Date??
    public var authorID: Int??
    public var title: String??
    public var content: String??
    public var password: String??
    public var excerpt: String??
    public var slug: String??
    public var featuredImageID: Int??

    // Pages
    public var parentPageID: Int??

    // Posts
    public var format: String??
    public var isSticky: Bool?
    public var tags: [String]?
    public var categoryIDs: [Int]?

    public init() {}
}

// MARK: - Diff

extension RemotePostCreateParameters {
    /// Returns a diff required to update from the `previous` to the current
    /// version of the post.
    public func changes(from previous: RemotePostCreateParameters) -> RemotePostUpdateParameters {
        var changes = RemotePostUpdateParameters()
        if previous.status != status {
            changes.status = status
        }
        if previous.date != date {
            changes.date = date
        }
        if previous.authorID != authorID {
            changes.authorID = authorID
        }
        if previous.title != title {
            changes.title = title
        }
        if previous.content != content {
            changes.content = content
        }
        if previous.password != password {
            changes.password = password
        }
        if previous.excerpt != excerpt {
            changes.excerpt = excerpt
        }
        if previous.slug != slug {
            changes.slug = slug
        }
        if previous.featuredImageID != featuredImageID {
            changes.featuredImageID = featuredImageID
        }
        if previous.parentPageID != parentPageID {
            changes.parentPageID = parentPageID
        }
        if previous.format != format {
            changes.format = format
        }
        if previous.isSticky != isSticky {
            changes.isSticky = isSticky
        }
        if previous.tags != tags {
            changes.tags = tags
        }
        if previous.categoryIDs != categoryIDs {
            changes.categoryIDs = categoryIDs
        }
        return changes
    }

    /// Applies the diff to the receiver.
    public mutating func apply(_ changes: RemotePostUpdateParameters) {
        if let status = changes.status {
            self.status = status
        }
        if let date = changes.date {
            self.date = date
        }
        if let authorID = changes.authorID {
            self.authorID = authorID
        }
        if let title = changes.title {
            self.title = title
        }
        if let content = changes.content {
            self.content = content
        }
        if let password = changes.password {
            self.password = password
        }
        if let excerpt = changes.excerpt {
            self.excerpt = excerpt
        }
        if let slug = changes.slug {
            self.slug = slug
        }
        if let featuredImageID = changes.featuredImageID {
            self.featuredImageID = featuredImageID
        }
        if let parentPageID = changes.parentPageID {
            self.parentPageID = parentPageID
        }
        if let format = changes.format {
            self.format = format
        }
        if let isSticky = changes.isSticky {
            self.isSticky = isSticky
        }
        if let tags = changes.tags {
            self.tags = tags
        }
        if let categoryIDs = changes.categoryIDs {
            self.categoryIDs = categoryIDs
        }
    }
}

// MARK: - Encoding (WP.COM REST API)

private enum RemotePostWordPressComCodingKeys: String, CodingKey {
    case ifNotModifiedSince = "if_not_modified_since"
    case type
    case status
    case date
    case authorID = "author"
    case title
    case content
    case password
    case excerpt
    case slug
    case featuredImageID = "featured_image"
    case parentPageID = "parent"
    case terms
    case format
    case isSticky = "sticky"
    case categoryIDs = "categories_by_id"

    static let postTags = "post_tag"
}

struct RemotePostCreateParametersWordPressComEncoder: Encodable {
    let parameters: RemotePostCreateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostWordPressComCodingKeys.self)
        try container.encodeIfPresent(parameters.type, forKey: .type)
        try container.encodeIfPresent(parameters.status, forKey: .status)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeIfPresent(parameters.title, forKey: .title)
        try container.encodeIfPresent(parameters.content, forKey: .content)
        try container.encodeIfPresent(parameters.password, forKey: .password)
        try container.encodeIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeIfPresent(parameters.slug, forKey: .slug)
        try container.encodeIfPresent(parameters.featuredImageID, forKey: .featuredImageID)

        // Pages
        if let parentPageID = parameters.parentPageID {
            try container.encodeIfPresent(parentPageID, forKey: .parentPageID)
        }

        // Posts
        try container.encodeIfPresent(parameters.format, forKey: .format)
        if !parameters.tags.isEmpty {
            try container.encode([RemotePostWordPressComCodingKeys.postTags: parameters.tags], forKey: .terms)
        }
        if !parameters.categoryIDs.isEmpty {
            try container.encodeIfPresent(parameters.categoryIDs, forKey: .categoryIDs)
        }
        if parameters.isSticky {
            try container.encode(parameters.isSticky, forKey: .isSticky)
        }
    }
}

struct RemotePostUpdateParametersWordPressComEncoder: Encodable {
    let parameters: RemotePostUpdateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostWordPressComCodingKeys.self)
        try container.encodeIfPresent(parameters.ifNotModifiedSince, forKey: .ifNotModifiedSince)

        try container.encodeIfPresent(parameters.status, forKey: .status)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeIfPresent(parameters.title, forKey: .title)
        try container.encodeIfPresent(parameters.content, forKey: .content)
        try container.encodeIfPresent(parameters.password, forKey: .password)
        try container.encodeIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeIfPresent(parameters.slug, forKey: .slug)
        try container.encodeIfPresent(parameters.featuredImageID, forKey: .featuredImageID)

        // Pages
        if let parentPageID = parameters.parentPageID {
            try container.encodeIfPresent(parentPageID, forKey: .parentPageID)
        }

        // Posts
        try container.encodeIfPresent(parameters.format, forKey: .format)
        if let tags = parameters.tags {
            try container.encode([RemotePostWordPressComCodingKeys.postTags: tags], forKey: .terms)
        }
        try container.encodeIfPresent(parameters.categoryIDs, forKey: .categoryIDs)
        try container.encodeIfPresent(parameters.isSticky, forKey: .isSticky)
    }
}

// MARK: - Encoding (XML-RPC)

private enum RemotePostXMLRPCCodingKeys: String, CodingKey {
    case ifNotModifiedSince = "if_not_modified_since"
    case type = "post_type"
    case postStatus = "post_status"
    case date = "date_created_gmt"
    case authorID = "wp_author_id"
    case title
    case content = "description"
    case password = "wp_password"
    case excerpt = "mt_excerpt"
    case slug = "wp_slug"
    case featuredImageID = "wp_post_thumbnail"
    case parentPageID = "wp_page_parent_id"
    case tags = "mt_keywords"
    case format = "wp_post_format"
    case isSticky = "sticky"
    case categoryIDs = "categories"

    static let postTags = "post_tag"
}

struct RemotePostCreateParametersXMLRPCEncoder: Encodable {
    let parameters: RemotePostCreateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostXMLRPCCodingKeys.self)
        try container.encode(parameters.type, forKey: .type)
        try container.encodeIfPresent(parameters.status, forKey: .postStatus)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeIfPresent(parameters.title, forKey: .title)
        try container.encodeIfPresent(parameters.content, forKey: .content)
        try container.encodeIfPresent(parameters.password, forKey: .password)
        try container.encodeIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeIfPresent(parameters.slug, forKey: .slug)
        try container.encodeIfPresent(parameters.featuredImageID, forKey: .featuredImageID)

        // Pages
        if let parentPageID = parameters.parentPageID {
            try container.encodeIfPresent(parentPageID, forKey: .parentPageID)
        }

        // Posts
        try container.encodeIfPresent(parameters.format, forKey: .format)
        if !parameters.tags.isEmpty {
            try container.encode(parameters.tags, forKey: .tags)
        }
        if !parameters.categoryIDs.isEmpty {
            try container.encodeIfPresent(parameters.categoryIDs, forKey: .categoryIDs)
        }
        if parameters.isSticky {
            try container.encode(parameters.isSticky, forKey: .isSticky)
        }
    }
}

struct RemotePostUpdateParametersXMLRPCEncoder: Encodable {
    let parameters: RemotePostUpdateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostXMLRPCCodingKeys.self)
        try container.encodeIfPresent(parameters.ifNotModifiedSince, forKey: .ifNotModifiedSince)
        try container.encodeIfPresent(parameters.status, forKey: .postStatus)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeIfPresent(parameters.title, forKey: .title)
        try container.encodeIfPresent(parameters.content, forKey: .content)
        try container.encodeIfPresent(parameters.password, forKey: .password)
        try container.encodeIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeIfPresent(parameters.slug, forKey: .slug)
        try container.encodeIfPresent(parameters.featuredImageID, forKey: .featuredImageID)

        // Pages
        if let parentPageID = parameters.parentPageID {
            try container.encodeIfPresent(parentPageID, forKey: .parentPageID)
        }

        // Posts
        try container.encodeIfPresent(parameters.format, forKey: .format)
        if let tags = parameters.tags {
            try container.encode(tags, forKey: .tags)
        }
        try container.encodeIfPresent(parameters.categoryIDs, forKey: .categoryIDs)
        try container.encodeIfPresent(parameters.isSticky, forKey: .isSticky)
    }
}
