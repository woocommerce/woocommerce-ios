import Foundation


/// Represents an OrderStatus Entity.
///
public struct OrderStatus: Decodable {
    public var name: String
    public let siteID: Int
    public let slug: String

    /// OrderStatus struct initializer.
    ///
    public init(name: String, siteID: Int, slug: String) {
        self.name = name
        self.siteID = siteID
        self.slug = slug
    }

    /// The public initializer for OrderStatus.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let siteID = try container.decode(Int.self, forKey: .siteID)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(name: name, siteID: siteID, slug: slug) // initialize the struct
    }
}


/// Defines all of the OrderNote's CodingKeys.
///
private extension OrderStatus {

    enum CodingKeys: String, CodingKey {
        case name   = "name"
        case siteID = "site_id"
        case slug   = "slug"
    }
}


// MARK: - Comparable Conformance
//
extension OrderStatus: Comparable {
    public static func == (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.name == rhs.name &&
            lhs.slug == rhs.slug
    }

    public static func < (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
        return lhs.siteID < rhs.siteID ||
            (lhs.siteID == rhs.siteID && lhs.name == rhs.name) ||
            (lhs.siteID == rhs.siteID && lhs.slug == rhs.slug)
    }
}
