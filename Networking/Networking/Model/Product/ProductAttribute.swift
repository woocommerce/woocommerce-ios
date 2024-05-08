#if os(iOS)

import Foundation
import Codegen

/// Represents a ProductAttribute entity.
///
public struct ProductAttribute: Codable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let siteID: Int64
    public let attributeID: Int64
    public let name: String
    public let position: Int
    public let visible: Bool
    public let variation: Bool
    public let options: [String]

    // Variation type products alter the structure of ProductAttribute.
    // Because of that, we need to also include this private `option` String as well. 🤯
    // For more details see: https://github.com/woocommerce/woocommerce-ios/issues/859
    private let option: String


    /// ProductAttribute initializer.
    ///
    public init(siteID: Int64,
                attributeID: Int64,
                name: String,
                position: Int,
                visible: Bool,
                variation: Bool,
                options: [String]) {
        self.siteID = siteID
        self.attributeID = attributeID
        self.name = name
        self.position = position
        self.visible = visible
        self.variation = variation
        self.options = options
        self.option = ""
    }

    /// Public initializer for ProductAttribute.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductAttributeDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let attributeID = container.failsafeDecodeIfPresent(Int64.self, forKey: .attributeID) ?? 0
        let name = container.failsafeDecodeIfPresent(String.self, forKey: .name) ?? String()
        let position = container.failsafeDecodeIfPresent(Int.self, forKey: .position) ?? 0
        let visible = container.failsafeDecodeIfPresent(Bool.self, forKey: .visible) ?? true
        let variation = container.failsafeDecodeIfPresent(Bool.self, forKey: .variation) ?? true

        var options = container.failsafeDecodeIfPresent([String].self, forKey: .options) ?? [String]()
        if options.isEmpty {
            // This `ProductAttribute` may be linked to a variation type product → check if the `option` field contains anything.
            if let variationTypeOption = container.failsafeDecodeIfPresent(String.self, forKey: .option) {
                options.append(variationTypeOption)
            }
        }

        self.init(siteID: siteID,
                  attributeID: attributeID,
                  name: name,
                  position: position,
                  visible: visible,
                  variation: variation,
                  options: options)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(attributeID, forKey: .attributeID)
        try container.encode(name, forKey: .name)
        try container.encode(options, forKey: .options)
        try container.encode(position, forKey: .position)
        try container.encode(visible, forKey: .visible)
        try container.encode(variation, forKey: .variation)
    }
}

public extension ProductAttribute {
    /// Returns weather an attribute belongs to a product(local) or to the store(global)
    ///
    var isLocal: Bool {
        attributeID == 0 // Currently the only way to know if an attribute is local is if it has a zero ID
    }

    /// Returns weather an attribute belongs to a product(local) or to the store(global)
    ///
    var isGlobal: Bool {
        !isLocal
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
        case option         = "option"  // Exists because of variation type products only
    }
}


// MARK: - Comparable Conformance
//
extension ProductAttribute: Comparable {
    public static func < (lhs: ProductAttribute, rhs: ProductAttribute) -> Bool {
        return lhs.attributeID < rhs.attributeID ||
            (lhs.attributeID == rhs.attributeID && lhs.name < rhs.name) ||
            (lhs.attributeID == rhs.attributeID && lhs.name == rhs.name && lhs.position < rhs.position)
    }
}

// MARK: - Decoding Errors
//
enum ProductAttributeDecodingError: Error {
    case missingSiteID
}

#endif
