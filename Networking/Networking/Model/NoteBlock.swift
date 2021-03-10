import Foundation


// MARK: - NotificationBlock Implementation
//
public struct NoteBlock: Equatable, GeneratedFakeable {

    /// Parsed Media Entities.
    ///
    public let media: [NoteMedia]

    /// Parsed Range Entities.
    ///
    public let ranges: [NoteRange]

    /// Block Associated Text.
    ///
    public let text: String?

    /// Available Actions collection.
    ///
    private let actions: [String: Bool]

    /// Meta Fields collection.
    ///
    public let meta: MetaContainer

    /// Raw Type, expressed as a string.
    ///
    private let type: String?



    /// Designated Initializer.
    ///
    public init(media: [NoteMedia], ranges: [NoteRange], text: String?, actions: [String: Bool], meta: [String: AnyCodable], type: String?) {
        self.media = media
        self.ranges = ranges
        self.text = text
        self.actions = actions
        self.meta = MetaContainer(payload: meta)
        self.type = type
    }
}


// MARK: - Decodable Conformance
//
extension NoteBlock: Decodable {

    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let media = container.failsafeDecodeIfPresent([NoteMedia].self, forKey: .media) ?? []
        let ranges = container.failsafeDecodeIfPresent([NoteRange].self, forKey: .ranges) ?? []
        let text = try container.decodeIfPresent(String.self, forKey: .text)
        let actions = try container.decodeIfPresent([String: Bool].self, forKey: .actions) ?? [:]
        let meta = try container.decodeIfPresent([String: AnyCodable].self, forKey: .meta) ?? [:]
        let type = try container.decodeIfPresent(String.self, forKey: .type)

        self.init(media: media, ranges: ranges, text: text, actions: actions, meta: meta, type: type)
    }
}


// MARK: - Computed Properties
//
extension NoteBlock {

    /// Returns the current Block's Kind. SORRY: Duck Typing code below.
    /// Calypso Ref.:
    ///    https://github.com/Automattic/wp-calypso/blob/823e0d6d0e5dc92ecafc8f4e09dbb88c7862e1b6/client/notifications/src/panel/templates/functions.jsx#L171
    ///
    public var kind: Kind {
        if type == Kind.user.rawValue {
            return .user
        }

        if let _ = meta.identifier(forKey: .comment), let _ = meta.identifier(forKey: .site) {
            return .comment
        }

        if let mediaKind = media.first?.kind, [.image, .badge].contains(mediaKind) {
            return .image
        }

        return .text
    }
}


// MARK: - Actions
//
extension NoteBlock {

    /// Returns *true* if a given action is available.
    ///
    public func isActionEnabled(_ action: Action) -> Bool {
        return actions[action.rawValue] != nil
    }

    /// Returns *true* if a given action is toggled on. (I.e.: Approval = On >> the comment is currently approved).
    ///
    public func isActionOn(_ action: Action) -> Bool {
        return actions[action.rawValue] ?? false
    }
}


// MARK: - Nested Types
//
extension NoteBlock {

    /// Known kinds of Actions
    ///
    public enum Action: String {
        case approve    = "approve-comment"
        case follow     = "follow"
        case like       = "like-comment"
        case reply      = "replyto-comment"
        case spam       = "spam-comment"
        case trash      = "trash-comment"
    }

    /// Coding Keys
    ///
    enum CodingKeys: String, CodingKey {
        case actions
        case media
        case meta
        case ranges
        case type
        case text
        case user
    }

    /// Known kinds of Blocks
    ///
    public enum Kind: String {
        case text
        case image      // Includes Badges and Images
        case user
        case comment
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: NoteBlock, rhs: NoteBlock) -> Bool {
    return lhs.media == rhs.media &&
            lhs.ranges == rhs.ranges &&
            lhs.text == rhs.text &&
            lhs.kind == rhs.kind
}
