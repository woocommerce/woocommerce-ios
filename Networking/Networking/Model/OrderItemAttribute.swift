import Codegen

/// Represents an attribute of an `OrderItem` in its `attributes` property.
///
/// Currently, the use case is:
/// 1. When an order item is a variation and the attributes are its variation attributes.
/// 2. Product Add-Ons are stored as attributes.
///
/// Only attributes with `String` values are supported.
///
public struct OrderItemAttribute: Decodable, Hashable, Equatable, Sendable, GeneratedFakeable, GeneratedCopiable {
    public let metaID: Int64
    public let name: String
    public let value: String

    public init(metaID: Int64, name: String, value: String) {
        self.metaID = metaID
        self.name = name
        self.value = value
    }

    /// The public initializer for OrderItemAttribute.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metaID = try container.decode(Int64.self, forKey: .metaID)
        let name = try container.decode(String.self, forKey: .name)
        let value = try container.decodeIfPresent(String.self, forKey: .value)?.strippedHTML ?? ""

        // initialize the struct
        self.init(metaID: metaID, name: name, value: value)
    }
}

/// Defines all of the OrderItemAttribute's CodingKeys.
///
private extension OrderItemAttribute {
    enum CodingKeys: String, CodingKey {
        case metaID = "id"
        case name = "display_key"
        case value = "display_value"
    }
}
