import Foundation

/// Represents an OrderCountItem Entity.
/// OrderCountItem represents the number of Orders for a given status
///
public struct OrderCountItem: Decodable {
    public let slug: String
    public let name: String
    public let total: Int

    public init(slug: String, name: String, total: Int) {
        self.slug = slug
        self.name = name
        self.total = total
    }

    /// Public initialiser
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let slug = try container.decode(String.self, forKey: .slug)
        let name = try container.decode(String.self, forKey: .name)
        let total = try container.decode(Int.self, forKey: .total)

        self.init(slug: slug, name: name, total: total)
    }
}


/// Defines all of the OrderCountItem CodingKeys
///
private extension OrderCountItem {

    enum CodingKeys: String, CodingKey {
        case slug
        case name
        case total
    }
}

// MARK: - Comparable Conformance
//
extension OrderCountItem: Comparable {

    public static func == (lhs: OrderCountItem, rhs: OrderCountItem) -> Bool {
        return lhs.slug == rhs.slug &&
            lhs.name == rhs.name &&
            lhs.total == rhs.total
    }

    public static func < (lhs: OrderCountItem, rhs: OrderCountItem) -> Bool {
        return lhs.slug == rhs.slug &&
            lhs.name == rhs.name &&
            lhs.total < rhs.total
    }
}
