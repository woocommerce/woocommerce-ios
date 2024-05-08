#if os(iOS)

import Foundation
import Codegen

/// Represents a ProductImage entity.
///
public struct ProductImage: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let imageID: Int64
    public let dateCreated: Date    // gmt
    public let dateModified: Date?  // gmt
    public let src: String
    public let name: String?
    public let alt: String?

    /// ProductImage initializer.
    ///
    public init(imageID: Int64,
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

        let imageID = try container.decode(Int64.self, forKey: .imageID)
        let dateCreated = (try? container.decodeIfPresent(Date.self, forKey: .dateCreated)) ?? Date()
        let dateModified = try? container.decodeIfPresent(Date.self, forKey: .dateModified)
        let src = try container.decode(String.self, forKey: .src)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let alt: String? = {
            do {
                return try container.decodeIfPresent(String.self, forKey: .alt)
            } catch {
                DDLogError("⛔️ Error parsing `alt` for ProductImage ID \(imageID): \(error)")
                return nil
            }
        }()

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

#endif
