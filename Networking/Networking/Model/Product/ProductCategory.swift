import Foundation


/// Represents a ProductCategory entity.
///
public struct ProductCategory: Decodable {
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
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductCategoryDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let categoryID = try container.decode(Int64.self, forKey: .categoryID)
        // Some product endpoints don't include the parent category ID
        let parentID = container.failsafeDecodeIfPresent(Int64.self, forKey: .parentID) ?? 0
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(categoryID: categoryID, siteID: siteID, parentID: parentID, name: name, slug: slug)
    }
}


/// Defines all of the ProductCategory CodingKeys
///
private extension ProductCategory {
    enum CodingKeys: String, CodingKey {
        case categoryID = "id"
        case name       = "name"
        case slug       = "slug"
        case parentID   = "parent"
    }
}


// MARK: - Comparable Conformance
//
extension ProductCategory: Comparable {
    public static func == (lhs: ProductCategory, rhs: ProductCategory) -> Bool {
        return lhs.categoryID == rhs.categoryID &&
        lhs.siteID == rhs.siteID &&
        lhs.parentID == rhs.parentID &&
        lhs.name == rhs.name &&
        lhs.slug == rhs.slug
    }

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
