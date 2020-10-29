public struct OrderItemAttribute: Decodable, Hashable, Equatable {
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
        let value = try container.decode(String.self, forKey: .value)

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
