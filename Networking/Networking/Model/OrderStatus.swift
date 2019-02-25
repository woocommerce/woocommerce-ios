import Foundation


/// Represents an OrderStatus Entity.
///
public struct OrderStatus: Decodable {
    public var name: String
    public let slug: String

    /// OrderStatus struct initializer.
    ///
    public init(name: String, slug: String) {
        self.name = name
        self.slug = slug
    }

    /// The public initializer for OrderStatus.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(name: name, slug: slug) // initialize the struct
    }
}


/// Defines all of the OrderStatus's CodingKeys.
///
private extension OrderStatus {

    enum CodingKeys: String, CodingKey {
        case name   = "name"
        case slug   = "slug"
    }
}


// MARK: - Comparable Conformance
//
extension OrderStatus: Comparable {
    public static func == (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
        return lhs.name == rhs.name &&
            lhs.slug == rhs.slug
    }

    public static func < (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
        return lhs.name < rhs.name ||
            (lhs.name == rhs.name && lhs.slug < rhs.slug)
    }
}
