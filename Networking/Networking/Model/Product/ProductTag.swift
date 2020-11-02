import Foundation


/// Represents a ProductTag entity.
///
public struct ProductTag: Codable {
    public let siteID: Int64
    public let tagID: Int64
    public let name: String
    public let slug: String

    /// ProductTag initializer.
    ///
    public init(siteID: Int64,
                tagID: Int64,
                name: String,
                slug: String) {
        self.siteID = siteID
        self.tagID = tagID
        self.name = name
        self.slug = slug
    }

    /// Public initializer for ProductTag.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductTagDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let tagID = try container.decode(Int64.self, forKey: .tagID)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)

        self.init(siteID: siteID, tagID: tagID, name: name, slug: slug)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(tagID, forKey: .tagID)
        try container.encode(name, forKey: .name)
        try container.encode(slug, forKey: .slug)
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
        return lhs.siteID == rhs.siteID &&
            lhs.tagID == rhs.tagID &&
            lhs.name == rhs.name &&
            lhs.slug == rhs.slug
    }

    public static func < (lhs: ProductTag, rhs: ProductTag) -> Bool {
        return lhs.tagID < rhs.tagID ||
            (lhs.tagID == rhs.tagID && lhs.name < rhs.name) ||
            (lhs.tagID == rhs.tagID && lhs.name == rhs.name && lhs.slug < rhs.slug)
    }
}

// MARK: - Decoding Errors
//
enum ProductTagDecodingError: Error {
    case missingSiteID
}
