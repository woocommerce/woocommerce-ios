import Foundation
import Codegen

/// Represents an Inbox Note entity.
/// Doc: p91TBi-6o2
///
public struct InboxNote: GeneratedCopiable, GeneratedFakeable, Equatable {
    /// `siteID` should be set on a copy in the Mapper as it's not returned by the API.
    /// Using a default here gives us the benefit of synthesised codable conformance.
    /// `private(set) public var` is required so that `siteID` will still be on the synthesised`init` which `copy()` uses
    private(set) public var siteID: Int64 = 0

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
    public let isDeleted: String

    /// Date the note was created (GMT).
    ///
    public let dateCreated: Date
}


// MARK: - Codable Conformance

/// Defines all of the InboxNote CodingKeys
extension InboxNote: Codable {
    enum CodingKeys: String, CodingKey {
        case siteID
        case id
        case name
        case type
        case status
        case actions
        case title
        case content
        case isDeleted = "is_deleted"
        case dateCreated = "date_created_gmt"
    }
}
