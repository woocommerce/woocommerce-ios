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

        let attributeID = try container.decode(Int.self, forKey: .attributeID)
        let name = try container.decode(String.self, forKey: .name)
        let position = try container.decode(Int.self, forKey: .position)
        let visible = try container.decode(Bool.self, forKey: .visible)
        let variation = try container.decode(Bool.self, forKey: .variation)
        let options = try container.decode([String].self, forKey: .options)

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
