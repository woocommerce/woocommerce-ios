import Foundation

/// Represents a Product Variation Attribute Entity.
///
public struct ProductVariationAttribute: Decodable {
    public let id: Int64
    public let name: String
    public let option: String

    public init(id: Int64, name: String, option: String) {
        self.id = id
        self.name = name
        self.option = option
    }
}

// MARK: - Equatable Conformance
//
extension ProductVariationAttribute: Equatable {
    public static func == (lhs: ProductVariationAttribute, rhs: ProductVariationAttribute) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.option == rhs.option
    }
}
