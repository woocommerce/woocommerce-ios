import Codegen

/// Represents a product add-on (from the Product Add-ons extension) of an `OrderItem` in its `attributes` (meta) property.
/// The value type is string but could be from different types like numbers in the API.
///
public struct OrderItemProductAddOn: Decodable, Hashable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let addOnID: Int64
    public let key: String
    public let value: String

    public init(addOnID: Int64, key: String, value: String) {
        self.addOnID = addOnID
        self.key = key
        self.value = value
    }

    /// The public initializer for OrderItemProductAddOn.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let addOnID = container.failsafeDecodeIfPresent(targetType: Int64.self, forKey: .addOnID, alternativeTypes: [.string(transform: {
            Int64($0) ?? 0
        })]) ?? 0
        let key = try container.decode(String.self, forKey: .key)
        let value = try container.decode(String.self, forKey: .value)

        self.init(addOnID: addOnID, key: key, value: value)
    }
}

/// Defines all of the OrderItemProductAddOn's CodingKeys.
///
private extension OrderItemProductAddOn {
    enum CodingKeys: String, CodingKey {
        case addOnID = "id"
        case key
        case value
    }
}
