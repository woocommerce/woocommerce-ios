import Foundation


// MARK: - Note: Represents a WordPress.com Notification
//
public struct Note {

    /// Notification's Primary Key.
    ///
    public let noteId: Int64

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

    /// Notification Type.
    ///
    public let type: String?

    /// Associated Resource's URL.
    ///
    public let url: String?

    /// Plain Title ("1 Like" / Etc).
    ///
    public let title: String?

    /// Raw Subject Blocks.
    ///
    public let subject: [NoteBlock]

    /// Raw Header Blocks.
    ///
    public let header: [NoteBlock]

    /// Raw Body Blocks.
    ///
    public let body: [NoteBlock]

    /// Raw Associated Metadata.
    ///
    public let meta: MetaContainer



    /// Designed Initializer.
    ///
    public init(noteId: Int64,
                hash: Int64,
                read: Bool,
                icon: String?,
                noticon: String?,
                timestamp: String,
                type: String,
                url: String?,
                title: String?,
                subject: [NoteBlock],
                header: [NoteBlock],
                body: [NoteBlock],
                meta: [String: AnyCodable]) {

        self.noteId = noteId
        self.hash = hash
        self.read = read
        self.icon = icon
        self.noticon = noticon
        self.timestamp = timestamp
        self.timestampAsDate = DateFormatter.Defaults.dateTimeFormatter.date(from: timestamp) ?? Date()
        self.type = type
        self.kind = Kind(rawValue: type) ?? .unknown
        self.url = url
        self.title = title
        self.subject = subject
        self.header = header
        self.body = body
        self.meta = MetaContainer(payload: meta)
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
        let url = container.failsafeDecodeIfPresent(String.self, forKey: .url)
        let title = container.failsafeDecodeIfPresent(String.self, forKey: .title)

        let subject = container.failsafeDecodeIfPresent([NoteBlock].self, forKey: .subject) ?? []
        let header = container.failsafeDecodeIfPresent([NoteBlock].self, forKey: .header) ?? []
        let body = container.failsafeDecodeIfPresent([NoteBlock].self, forKey: .body) ?? []
        let meta = container.failsafeDecodeIfPresent([String: AnyCodable].self, forKey: .meta) ?? [:]

        self.init(noteId: noteID,
                  hash: hash,
                  read: read,
                  icon: icon,
                  noticon: noticon,
                  timestamp: timestamp,
                  type: type,
                  url: url,
                  title: title,
                  subject: subject,
                  header: header,
                  body: body,
                  meta: meta)
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
}
