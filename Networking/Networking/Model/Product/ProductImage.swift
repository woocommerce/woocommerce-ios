import Foundation


/// Represents a ProductImage entity.
///
public struct ProductImage: Codable {
    public let imageID: Int
    public let dateCreated: Date    // gmt
    public let dateModified: Date?  // gmt
    public let src: String
    public let name: String?
    public let alt: String?

    /// ProductImage initializer.
    ///
    public init(imageID: Int,
                dateCreated: Date,
                dateModified: Date?,
                src: String,
                name: String?,
                alt: String?) {
        self.imageID = imageID
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.src = src
        self.name = name
        self.alt = alt
    }

    /// Public initializer for ProductImage
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let imageID = try container.decode(Int.self, forKey: .imageID)
        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified)
        let src = try container.decode(String.self, forKey: .src)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let alt = try container.decodeIfPresent(String.self, forKey: .alt)

        self.init(imageID: imageID,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  src: src,
                  name: name,
                  alt: alt)
    }
}


/// Defines all the ProductImage CodingKeys.
///
private extension ProductImage {
    enum CodingKeys: String, CodingKey {
        case imageID        = "id"
        case dateCreated    = "date_created_gmt"
        case dateModified   = "date_modified_gmt"
        case src            = "src"
        case name           = "name"
        case alt            = "alt"
    }
}


// MARK: - Comparable Conformance
//
extension ProductImage: Comparable {
    public static func == (lhs: ProductImage, rhs: ProductImage) -> Bool {
        return lhs.imageID == rhs.imageID &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.dateModified == rhs.dateModified &&
            lhs.src == rhs.src &&
            lhs.name == rhs.name &&
            lhs.alt == rhs.alt
    }

    public static func < (lhs: ProductImage, rhs: ProductImage) -> Bool {
        return lhs.imageID < rhs.imageID ||
            (lhs.imageID == rhs.imageID && lhs.dateCreated < rhs.dateCreated) ||
            (lhs.imageID == rhs.imageID && lhs.dateCreated == rhs.dateCreated && lhs.src < rhs.src)
    }
}
