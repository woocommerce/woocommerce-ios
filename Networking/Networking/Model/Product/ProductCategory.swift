import Foundation
import Codegen

/// Represents a ProductCategory entity.
///
public struct ProductCategory: Codable, Equatable, GeneratedFakeable {
    public let categoryID: Int64
    public let siteID: Int64
    public let parentID: Int64
    public let name: String
    public let slug: String

    /// ProductCategory initializer.
    ///
    public init(categoryID: Int64,
                siteID: Int64,
                parentID: Int64,
                name: String,
                slug: String) {
        self.categoryID = categoryID
        self.siteID = siteID
        self.parentID = parentID
        self.name = name
        self.slug = slug
    }

    /// Public initializer for ProductCategory.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let siteID = ProductCategory.siteID(from: decoder, container: container) else {
            throw ProductCategoryDecodingError.missingSiteID
        }

        let categoryID = try container.decode(Int64.self, forKey: .categoryID)
        // Some product endpoints don't include the parent category ID
        let parentID = container.failsafeDecodeIfPresent(Int64.self, forKey: .parentID) ?? 0
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(categoryID: categoryID, siteID: siteID, parentID: parentID, name: name, slug: slug)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(name, forKey: .name)
        try container.encode(slug, forKey: .slug)
        try container.encode(siteID, forKey: .siteID)
        try container.encode(parentID, forKey: .parentID)
    }
}


/// Defines all of the ProductCategory CodingKeys
///
private extension ProductCategory {
    enum CodingKeys: String, CodingKey {
        case siteID     = "siteID"
        case categoryID = "id"
        case name       = "name"
        case slug       = "slug"
        case parentID   = "parent"
    }
}

private extension ProductCategory {
    /// Provides the siteID, that can be found as a encoded value or in the Decoder user info
    ///
    private static func siteID(from decoder: Decoder, container: KeyedDecodingContainer<ProductCategory.CodingKeys>) -> Int64? {
        var siteID: Int64?

        if let userInfoSiteID = decoder.userInfo[.siteID] as? Int64 {
            siteID = userInfoSiteID
        } else if let decodedSiteID = try? container.decode(Int64.self, forKey: .siteID) {
            siteID = decodedSiteID
        }

        return siteID
    }
}


// MARK: - Comparable Conformance
//
extension ProductCategory: Comparable {
    public static func < (lhs: ProductCategory, rhs: ProductCategory) -> Bool {
        return lhs.categoryID < rhs.categoryID ||
            (lhs.categoryID == rhs.categoryID && lhs.name < rhs.name) ||
            (lhs.categoryID == rhs.categoryID && lhs.name == rhs.name && lhs.slug < rhs.slug)
    }
}

// MARK: - Constants
//
public extension ProductCategory {
    /// Value the API sends on the `parentID` field when a category does not have a parent.
    static let noParentID: Int64 = 0
}

// MARK: - Decoding Errors
//
enum ProductCategoryDecodingError: Error {
    case missingSiteID
}
