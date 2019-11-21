import Foundation


/// Represents a ProductTag entity.
///
public struct ProductTag: Codable {
    public let tagID: Int
    public let name: String
    public let slug: String

    /// ProductTag initializer.
    ///
    public init(tagID: Int,
                name: String,
                slug: String) {
        self.tagID = tagID
        self.name = name
        self.slug = slug
    }

    /// Public initializer for ProductTag.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let tagID = try container.decode(Int.self, forKey: .tagID)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(tagID: tagID, name: name, slug: slug)
    }
}


/// Defines all of the ProductTag CodingKeys
///
private extension ProductTag {
    enum CodingKeys: String, CodingKey {
        case tagID  = "id"
        case name   = "name"
        case slug   = "slug"
    }
}


// MARK: - Comparable Conformance
//
extension ProductTag: Comparable {
    public static func == (lhs: ProductTag, rhs: ProductTag) -> Bool {
        return lhs.tagID == rhs.tagID &&
            lhs.name == rhs.name &&
            lhs.slug == rhs.slug
    }

    public static func < (lhs: ProductTag, rhs: ProductTag) -> Bool {
        return lhs.tagID < rhs.tagID ||
            (lhs.tagID == rhs.tagID && lhs.name < rhs.name) ||
            (lhs.tagID == rhs.tagID && lhs.name == rhs.name && lhs.slug < rhs.slug)
    }
}
