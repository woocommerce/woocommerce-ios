import Foundation
import Codegen

/// Represents a `AddOnGroup` entity that groups global add-ons.
///
public struct AddOnGroup: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    /// SiteID
    ///
    public let siteID: Int64

    /// Add-on group ID
    ///
    public let groupID: Int64

    /// Name of the group
    ///
    public let name: String

    /// Priority of the group
    ///
    public let priority: Int64

    /// Associated global add-ons
    ///
    public let addOns: [ProductAddOn]

    public init(siteID: Int64, groupID: Int64, name: String, priority: Int64, addOns: [ProductAddOn]) {
        self.siteID = siteID
        self.groupID = groupID
        self.name = name
        self.priority = priority
        self.addOns = addOns
    }
}

// MARK: Decoding
extension AddOnGroup {
    enum CodingKeys: String, CodingKey {
        case groupID = "id"
        case name
        case priority
        case addOns = "fields"
    }

    enum DecodingError: Error {
        case missingSiteID
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductCategoryDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(siteID: siteID,
                  groupID: try container.decode(Int64.self, forKey: .groupID),
                  name: try container.decode(String.self, forKey: .name),
                  priority: try container.decode(Int64.self, forKey: .priority),
                  addOns: try container.decode([ProductAddOn].self, forKey: .addOns))
    }
}
