import Foundation

/// Represents a ProductTag entity, used during a tag creation.
///
struct ProductTagFromBatchCreation: Decodable {
    let siteID: Int64
    let tagID: Int64
    let error: CreateError?
    let name, slug: String?

    /// ProductTagFromBatchCreation initializer.
    ///
    init(siteID: Int64,
                tagID: Int64,
                error: CreateError?,
                name: String?,
                slug: String?) {
        self.siteID = siteID
        self.tagID = tagID
        self.error = error
        self.name = name
        self.slug = slug
    }

    /// Initializer for ProductTagFromBatchCreation.
    ///
    init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductTagCreateDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let tagID = try container.decode(Int64.self, forKey: .tagID)
        let error = try container.decodeIfPresent(CreateError.self, forKey: .error)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let slug = try container.decodeIfPresent(String.self, forKey: .slug)

        self.init(siteID: siteID,
                  tagID: tagID,
                  error: error,
                  name: name,
                  slug: slug)
    }
}

// MARK: - CreateError
struct CreateError: Decodable {
    public let code, message: String
}

/// Defines all of the ProductTagFromBatchCreation CodingKeys
///
private extension ProductTagFromBatchCreation {
    enum CodingKeys: String, CodingKey {
        case tagID  = "id"
        case name   = "name"
        case slug   = "slug"
        case error  = "error"
    }
}

// MARK: - Decoding Errors
//
enum ProductTagCreateDecodingError: Error {
    case missingSiteID
}
