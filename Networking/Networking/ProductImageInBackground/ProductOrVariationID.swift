/// Identifiable data about a product or product variation.
public enum ProductOrVariationID: Equatable, Hashable, Codable {
    case product(id: Int64)
    case variation(productID: Int64, variationID: Int64)

    /// Returns the product ID for product type and variation ID for variation type.
    public var id: Int64 {
        switch self {
        case .product(let id):
            return id
        case .variation(_, let variationID):
            return variationID
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case productID
        case variationID
    }

    private enum CaseType: String, Codable {
        case product
        case variation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseType = try container.decode(CaseType.self, forKey: .type)
        switch caseType {
        case .product:
            let id = try container.decode(Int64.self, forKey: .id)
            self = .product(id: id)
        case .variation:
            let productID = try container.decode(Int64.self, forKey: .productID)
            let variationID = try container.decode(Int64.self, forKey: .variationID)
            self = .variation(productID: productID, variationID: variationID)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .product(let id):
            try container.encode(CaseType.product, forKey: .type)
            try container.encode(id, forKey: .id)
        case .variation(let productID, let variationID):
            try container.encode(CaseType.variation, forKey: .type)
            try container.encode(productID, forKey: .productID)
            try container.encode(variationID, forKey: .variationID)
        }
    }
}
