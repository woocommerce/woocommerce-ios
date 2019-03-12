import Foundation


/// Represents a ProductCategory entity.
///
public struct ProductCategory: Decodable {
    public let categoryID: Int
    public let name: String
    public let slug: String

    /// ProductCategory initializer.
    ///
    public init(categoryID: Int,
                name: String,
                slug: String) {
        self.categoryID = categoryID
        self.name = name
        self.slug = slug
    }

    /// Public initializer for ProductCategory.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let categoryID = try container.decode(Int.self, forKey: .categoryID)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(categoryID: categoryID, name: name, slug: slug)
    }
}


/// Defines all of the ProductCategory CodingKeys
///
private extension ProductCategory {
    enum CodingKeys: String, CodingKey {
        case categoryID = "id"
        case name       = "name"
        case slug       = "slug"
    }
}


// MARK: - Comparable Conformance
//
extension ProductCategory: Comparable {
    public static func == (lhs: ProductCategory, rhs: ProductCategory) -> Bool {
        return lhs.categoryID == rhs.categoryID &&
        lhs.name == rhs.name &&
        lhs.slug == rhs.slug
    }

    public static func < (lhs: ProductCategory, rhs: ProductCategory) -> Bool {
        return lhs.categoryID < rhs.categoryID ||
            (lhs.categoryID == rhs.categoryID && lhs.name < rhs.name) ||
            (lhs.categoryID == rhs.categoryID && lhs.name == rhs.name && lhs.slug < rhs.slug)
    }
}
