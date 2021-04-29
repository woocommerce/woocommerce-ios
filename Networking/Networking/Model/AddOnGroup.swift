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
