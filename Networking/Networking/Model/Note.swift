import Foundation


// MARK: - Note: Represents a WordPress.com Notification
//
public struct Note {


    /// Notification's Primary Key.
    ///
    public let noteID: Int64

    /// Notification's Hash.
    ///
    public let hash: Int64

    /// Indicates whether the note was already read, or not.
    ///
    public let read: Bool

    /// Associated Resource's Icon, as a plain string.
    ///
    public let icon: String?

    /// Noticon resource, associated with this notification.
    ///
    public let noticon: String?

    /// Timestamp as a String.
    ///
    public let timestamp: String

    /// Timestamp as a Date.
    ///
    public let timestampAsDate: Date

    /// Notification.Type expressed as a Swift Native enum.
    ///
    public let kind: Kind

    /// Notification.Subtype expressed as a Swift Native enum.
    ///
    public let subkind: Subkind?

    /// Notification Type.
    ///
    public let type: String?

    /// Notification Subtype.
    ///
    public let subtype: String?

    /// Associated Resource's URL.
    ///
    public let url: String?

    /// Plain Title ("1 Like" / Etc).
    ///
    public let title: String?


    /// Raw Subject Blocks as Data.
    ///
    public let subjectAsData: Data

    /// Subject Blocks.
    ///
    public let subject: [NoteBlock]


    /// Raw Header Blocks as Data.
    ///
    public let headerAsData: Data

    /// Header Blocks.
    ///
    public let header: [NoteBlock]


    /// Raw Body Blocks as Data.
    ///
    public let bodyAsData: Data

    /// Body Blocks.
    ///
    public let body: [NoteBlock]


    /// Raw Associated Metadata as Data.
    ///
    public let metaAsData: Data

    /// Associated Metadata.
    ///
    public let meta: MetaContainer


    /// Designed Initializer.
    ///
    public init(noteID: Int64,
                hash: Int64,
                read: Bool,
                icon: String?,
                noticon: String?,
                timestamp: String,
                type: String,
                subtype: String?,
                url: String?,
                title: String?,
                subject: Data,
                header: Data,
                body: Data,
                meta: Data) {

        self.noteID = noteID
        self.hash = hash
        self.read = read
        self.icon = icon
        self.noticon = noticon
        self.timestamp = timestamp
        self.timestampAsDate = DateFormatter.Defaults.iso8601.date(from: timestamp) ?? Date()
        self.type = type
        self.subtype = subtype
        self.kind = Kind(rawValue: type) ?? .unknown
        self.subkind = subtype.flatMap { Subkind(rawValue: $0) }
        self.url = url
        self.title = title

        self.subjectAsData = subject
        self.subject = (try? JSONDecoder().decode([NoteBlock].self, from: subject)) ?? []

        self.headerAsData = header
        self.header = (try? JSONDecoder().decode([NoteBlock].self, from: header)) ?? []

        self.bodyAsData = body
        self.body = (try? JSONDecoder().decode([NoteBlock].self, from: body)) ?? []

        self.metaAsData = meta
        let metaDict = (try? JSONDecoder().decode([String: AnyCodable].self, from: meta)) ?? [:]
        self.meta = MetaContainer(payload: metaDict)
    }
}


// MARK: - Decodable Conformance
//
extension Note: Decodable {

    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let noteID = try container.decode(Int64.self, forKey: .noteID)
        let hash = try container.decode(Int64.self, forKey: .hash)

        let read = container.failsafeDecodeIfPresent(booleanForKey: .read) ?? false
        let icon = container.failsafeDecodeIfPresent(String.self, forKey: .icon)
        let noticon = container.failsafeDecodeIfPresent(String.self, forKey: .noticon)
        let timestamp = container.failsafeDecodeIfPresent(stringForKey: .timestamp) ?? String()
        let type = container.failsafeDecodeIfPresent(String.self, forKey: .type) ?? String()
        let subtype = container.failsafeDecodeIfPresent(String.self, forKey: .subtype)
        let url = container.failsafeDecodeIfPresent(String.self, forKey: .url)
        let title = container.failsafeDecodeIfPresent(String.self, forKey: .title)

        let rawSubjectAsData = container.failsafeDecodeIfPresent([AnyCodable].self, forKey: .subject) ?? []
        let subjectAsData = try JSONEncoder().encode(rawSubjectAsData)

        let rawHeaderAsData = container.failsafeDecodeIfPresent([AnyCodable].self, forKey: .header) ?? []
        let headerAsData = try JSONEncoder().encode(rawHeaderAsData)

        let rawBodyAsData = container.failsafeDecodeIfPresent([AnyCodable].self, forKey: .body) ?? []
        let bodyAsData = try JSONEncoder().encode(rawBodyAsData)

        let rawMetaAsData = container.failsafeDecodeIfPresent([String: AnyCodable].self, forKey: .meta) ?? [:]
        let metaAsData = try JSONEncoder().encode(rawMetaAsData)

        self.init(noteID: noteID,
                  hash: hash,
                  read: read,
                  icon: icon,
                  noticon: noticon,
                  timestamp: timestamp,
                  type: type,
                  subtype: subtype,
                  url: url,
                  title: title,
                  subject: subjectAsData,
                  header: headerAsData,
                  body: bodyAsData,
                  meta: metaAsData)
    }
}


// MARK: - Nested Types
//
extension Note {

    /// Coding Keys
    ///
    enum CodingKeys: String, CodingKey {
        case noteID = "id"
        case hash = "note_hash"
        case read
        case icon
        case noticon
        case timestamp
        case type
        case subtype
        case url
        case title
        case subject
        case header
        case body
        case meta
    }

    /// Known Notification Kinds
    ///
    public enum Kind: String {
        case automattcher
        case comment
        case commentLike = "comment_like"
        case follow
        case like
        case newPost = "new_post"
        case post
        case storeOrder = "store_order"
        case user
        case unknown
    }

    /// Known Notification Subkind(s)
    ///
    public enum Subkind: String {
        case storeReview = "store_review"
    }
}
