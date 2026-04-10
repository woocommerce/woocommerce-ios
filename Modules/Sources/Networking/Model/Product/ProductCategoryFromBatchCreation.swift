import Foundation

/// Represents a ProductCategory entity, used during categories batch creation.
///
struct ProductCategoryFromBatchCreation: Decodable {
    let categoryID: Int64
    let siteID: Int64
    let parentID: Int64
    let error: CreateError?
    let name, slug: String?

    /// ProductCategoryFromBatchCreation initializer.
    ///
    init(categoryID: Int64,
         siteID: Int64,
         parentID: Int64,
         error: CreateError?,
         name: String?,
         slug: String?) {
        self.categoryID = categoryID
        self.siteID = siteID
        self.parentID = parentID
        self.error = error
        self.name = name
        self.slug = slug
    }

    /// Initializer for ProductCategoryFromBatchCreation.
    ///
    init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductCategoryCreateDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let categoryID = try container.decode(Int64.self, forKey: .categoryID)
        let error = try container.decodeIfPresent(CreateError.self, forKey: .error)
        let parentID = container.failsafeDecodeIfPresent(Int64.self, forKey: .parentID) ?? 0
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let slug = try container.decodeIfPresent(String.self, forKey: .slug)

        self.init(categoryID: categoryID,
                  siteID: siteID,
                  parentID: parentID,
                  error: error,
                  name: name,
                  slug: slug)
    }
}

/// Defines all of the ProductCategoryFromBatchCreation CodingKeys
///
private extension ProductCategoryFromBatchCreation {
    enum CodingKeys: String, CodingKey {
        case siteID     = "siteID"
        case categoryID = "id"
        case name       = "name"
        case slug       = "slug"
        case parentID   = "parent"
        case error      = "error"
    }
}

// MARK: - Decoding Errors
//
enum ProductCategoryCreateDecodingError: Error {
    case missingSiteID
}
