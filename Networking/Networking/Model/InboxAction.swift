import Foundation
import Codegen

/// Represents an Inbox Action entity.
/// Doc: p91TBi-6o2
///
public struct InboxAction: GeneratedCopiable, GeneratedFakeable, Equatable {

    /// Action ID in WP database.
    ///
    public let id: Int64

    /// Name of the action.
    ///
    public let name: String

    /// Label of the action.
    ///
    public let label: String

    /// All values: `unactioned`, `actioned`, `snoozed`. It seems there isn't a way to snooze a notification at the moment.
    ///
    public let status: String

    /// URL where the action points.
    ///
    public let url: String
}


// MARK: - Codable Conformance

/// Defines all of the InboxNote CodingKeys
extension InboxAction: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case label
        case status
        case url
    }
}
