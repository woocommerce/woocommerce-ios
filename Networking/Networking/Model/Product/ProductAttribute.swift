import Foundation


/// Represents a ProductAttribute entity.
///
public struct ProductAttribute: Decodable {
    public let attributeID: Int
    public let name: String
    public let position: Int
    public let visible: Bool
    public let variation: Bool
    public let options: [String]

    /// ProductAttribute initializer.
    ///
    public init(attributeID: Int,
                name: String,
                position: Int,
                visible: Bool,
                variation: Bool,
                options: [String]) {
        self.attributeID = attributeID
        self.name = name
        self.position = position
        self.visible = visible
        self.variation = variation
        self.options = options
    }

    /// Public initializer for ProductAttribute.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let attributeID = container.failsafeDecodeIfPresent(Int.self, forKey: .attributeID) ?? 0
        let name = container.failsafeDecodeIfPresent(String.self, forKey: .name) ?? String()
        let position = container.failsafeDecodeIfPresent(Int.self, forKey: .position) ?? 0
        let visible = container.failsafeDecodeIfPresent(Bool.self, forKey: .visible) ?? true
        let variation = container.failsafeDecodeIfPresent(Bool.self, forKey: .variation) ?? true
        let options = container.failsafeDecodeIfPresent([String].self, forKey: .options) ?? [String]()

        self.init(attributeID: attributeID,
                  name: name,
                  position: position,
                  visible: visible,
                  variation: variation,
                  options: options)
    }
}


/// Defines all the ProductAttribute CodingKeys.
///
private extension ProductAttribute {
    enum CodingKeys: String, CodingKey {
        case attributeID    = "id"
        case name           = "name"
        case position       = "position"
        case visible        = "visible"
        case variation      = "variation"
        case options        = "options"
    }
}


// MARK: - Comparable Conformance
//
extension ProductAttribute: Comparable {
    public static func == (lhs: ProductAttribute, rhs: ProductAttribute) -> Bool {
        return lhs.attributeID == rhs.attributeID &&
            lhs.name == rhs.name &&
            lhs.position == rhs.position &&
            lhs.visible == rhs.visible &&
            lhs.variation == rhs.variation &&
            lhs.options == rhs.options
    }

    public static func < (lhs: ProductAttribute, rhs: ProductAttribute) -> Bool {
        return lhs.attributeID < rhs.attributeID ||
            (lhs.attributeID == rhs.attributeID && lhs.name < rhs.name) ||
            (lhs.attributeID == rhs.attributeID && lhs.name == rhs.name && lhs.position < rhs.position)
    }
}
