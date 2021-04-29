import Foundation

/// Represents a `AddOnGroup` entity that groups global add-ons.
///
public struct AddOnGroup: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// SiteID
    ///
    let siteID: Int64

    /// Add-on group ID
    ///
    let groupID: Int64

    /// Name of the group
    ///
    let name: String

    /// Priority of the group
    ///
    let priority: Int64

    /// Associated global add-ons
    ///
    let addOns: [ProductAddOn]
}
