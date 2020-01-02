import Foundation


// MARK: - NoteRange
//
public struct NoteRange: Equatable {

    /// NoteRange.Type expressed as a Swift Native Enum.
    ///
    public let kind: Kind

    /// Type of the current Range
    ///
    public let type: String?

    /// Text Range Associated!
    ///
    public let range: NSRange

    /// Resource URL, if any.
    ///
    public let url: URL?

    /// Comment ID, if any.
    ///
    private(set) public var commentID: Int64?

    /// Post ID, if any.
    ///
    private(set) public var postID: Int64?

    /// Site ID, if any.
    ///
    private(set) public var siteID: Int64?

    /// User ID, if any.
    ///
    private(set) public var userID: Int64?

    /// String Payload, if any.
    ///
    private(set) public var value: String?



    /// Designated Initializer.
    ///
    init(type: String?, range: NSRange, url: URL?, identifier: Int64?, postID: Int64?, siteID: Int64?, value: String?) {
        self.kind = NoteRange.kind(forType: type, siteID: siteID, url: url)
        self.type = type
        self.range = range
        self.url = url
        self.value = value

        // Apologies about the following snippet: We just can't have nice things.
        // The `identifier` field has a different meaning, depending on what the Range's Kind actually is.
        //
        switch kind {
        case .comment:
            self.siteID = siteID
            self.postID = postID
            self.commentID = identifier
        case .post:
            self.siteID = siteID
            self.postID = identifier
        case .site:
            self.siteID = identifier ?? siteID
        case .user:
            self.userID = identifier
        default:
            break
        }
    }
}


// MARK: - Decodable Conformance
//
extension NoteRange: Decodable {

    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decodeIfPresent(String.self, forKey: .type)
        let range = try container.decode(arrayEncodedRangeForKey: .indices)
        let url = try container.decodeIfPresent(URL.self, forKey: .url)
        let identifier = try container.decodeIfPresent(Int64.self, forKey: .id)
        let postID = try container.decodeIfPresent(Int64.self, forKey: .postId)
        let siteID = try container.decodeIfPresent(Int64.self, forKey: .siteId)
        let value = try container.decodeIfPresent(String.self, forKey: .value)

        self.init(type: type, range: range, url: url, identifier: identifier, postID: postID, siteID: siteID, value: value)
    }
}


// MARK: - Parsing Helpers
//
private extension NoteRange {

    /// Parses the NoteRange.Type field into a Swift Native enum. Returns .unknown on failure.
    ///
    static func kind(forType type: String?, siteID: Int64?, url: URL?) -> Kind {
        if let type = type, let kind = Kind(rawValue: type) {
            return kind
        }

        if let _ = siteID {
            return .site
        }

        if let _ = url {
            return .link
        }

        return .unknown
    }
}


// MARK: - Nested Types
//
extension NoteRange {

    /// Coding Keys.
    ///
    enum CodingKeys: String, CodingKey {
        case type
        case url
        case indices
        case id
        case value
        case siteId = "site_id"
        case postId = "post_id"
    }

    /// Known Range Types.
    ///
    public enum Kind: String {
        case user
        case post
        case comment
        case stats
        case follow
        case blockquote
        case noticon
        case site
        case match
        case link
        case unknown
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: NoteRange, rhs: NoteRange) -> Bool {
    return lhs.type == rhs.type &&
            lhs.range == rhs.range &&
            lhs.url == rhs.url &&
            lhs.commentID == rhs.commentID &&
            lhs.postID == rhs.postID &&
            lhs.siteID == rhs.siteID &&
            lhs.userID == rhs.userID &&
            lhs.value == rhs.value
}
