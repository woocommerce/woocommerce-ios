import Foundation
import Codegen

/// Represents an Inbox Note entity.
/// Doc: p91TBi-6o2
///
public struct InboxNote: GeneratedCopiable, GeneratedFakeable, Equatable {

    /// Site Identifier.
    ///
    public let siteID: Int64

    /// Note ID in WP database.
    ///
    public let id: Int64

    /// Unique identifier that corresponds to `slug` in WCCOM JSON.
    ///
    public let name: String

    /// WC Admin shows types `info`, `marketing`, `survey` and `warning` in the WC Admin API requests.
    ///
    public let type: String

    /// All values: `unactioned`, `actioned`, `snoozed`. It seems there isn't a way to snooze a notification at the moment.
    ///
    public let status: String

    /// When the user takes any actions on the notification (other than dismissing it),
    /// we make an API request to update the notification’s status as “actioned.”
    ///
    public let actions: [InboxAction]

    /// Title of the note.
    ///
    public let title: String

    /// The content of the note.
    ///
    public let content: String

    /// Registers whether the note is deleted or not.
    ///
    public let isDeleted: Bool

    /// Registers whether the note is read or not.
    ///
    public let isRead: Bool

    /// Date the note was created (GMT).
    ///
    public let dateCreated: Date
}


// MARK: - Codable Conformance

/// Defines all of the InboxNote CodingKeys
extension InboxNote: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw InboxNoteDecodingError.missingSiteID
        }
        let id = try container.decode(Int64.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let type = try container.decode(String.self, forKey: .type)
        let status = try container.decode(String.self, forKey: .status)
        let actions = try container.decode([InboxAction].self, forKey: .actions)
        let title = try container.decode(String.self, forKey: .title)
        let content = try container.decode(String.self, forKey: .content)
        let isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        let isRead = try container.decode(Bool.self, forKey: .isRead)
        let dateCreated = try container.decode(Date.self, forKey: .dateCreated)

        self.init(siteID: siteID,
                  id: id,
                  name: name,
                  type: type,
                  status: status,
                  actions: actions,
                  title: title,
                  content: content,
                  isDeleted: isDeleted,
                  isRead: isRead,
                  dateCreated: dateCreated)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case status
        case actions
        case title
        case content
        case isDeleted = "is_deleted"
        case isRead = "is_read"
        case dateCreated = "date_created_gmt"
    }
}

// MARK: - Decoding Errors
//
enum InboxNoteDecodingError: Error {
    case missingSiteID
}
