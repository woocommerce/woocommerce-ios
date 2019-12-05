import Foundation

/// Represents a ProductShippingClass entity.
///
public struct ProductShippingClass: Decodable {
    // Entities.
    public let count: Int64
    public let descriptionHTML: String?
    public let name: String
    public let shippingClassID: Int64
    public let siteID: Int64
    public let slug: String

    /// ProductShippingClass initializer.
    ///
    public init(count: Int64,
                descriptionHTML: String?,
                name: String,
                shippingClassID: Int64,
                siteID: Int64,
                slug: String) {
        // Entities.
        self.count = count
        self.descriptionHTML = descriptionHTML
        self.name = name
        self.shippingClassID = shippingClassID
        self.siteID = siteID
        self.slug = slug
    }


    /// Public initializer for ProductShippingClass.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductShippingClassDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Entities.
        let count = try container.decode(Int64.self, forKey: .count)
        let descriptionHTML = try container.decodeIfPresent(String.self, forKey: .descriptionHTML)
        let name = try container.decode(String.self, forKey: .name)
        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)
        let slug = try container.decode(String.self, forKey: .slug)


        self.init(count: count,
                  descriptionHTML: descriptionHTML,
                  name: name,
                  shippingClassID: shippingClassID,
                  siteID: siteID,
                  slug: slug)
    }
}


/// Defines all of the ProductShippingClass CodingKeys
///
private extension ProductShippingClass {
    enum CodingKeys: String, CodingKey {
        case count
        case descriptionHTML = "description"
        case name
        case shippingClassID = "id"
        case siteID
        case slug
    }
}


// MARK: - Equatable Conformance
//
extension ProductShippingClass: Equatable {
    public static func == (lhs: ProductShippingClass, rhs: ProductShippingClass) -> Bool {
        return lhs.count == rhs.count &&
            lhs.descriptionHTML == rhs.descriptionHTML &&
            lhs.name == rhs.name &&
            lhs.shippingClassID == rhs.shippingClassID &&
            lhs.siteID == rhs.siteID &&
            lhs.slug == rhs.slug
    }
}


// MARK: - Decoding Errors
//
enum ProductShippingClassDecodingError: Error {
    case missingSiteID
}
