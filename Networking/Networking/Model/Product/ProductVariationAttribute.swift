import Foundation
import Codegen

/// Represents a Product Variation Attribute Entity.
///
public struct ProductVariationAttribute: Codable, Equatable, GeneratedFakeable {
    public let id: Int64
    public let name: String
    public let option: String

    public init(id: Int64, name: String, option: String) {
        self.id = id
        self.name = name
        self.option = option
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(option, forKey: .option)
    }
}

/// Defines all of the ProductVariationAttribute CodingKeys
///
private extension ProductVariationAttribute {

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case option
    }
}
