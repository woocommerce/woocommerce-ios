import Foundation


/// Represents a ProductShippingClass entity.
///
public struct ProductShippingClass: Decodable {
    public let shippingClassID: Int64
    public let siteID: Int64
    public let name: String
    public let slug: String
    public let descriptionHTML: String?
    public let count: Int64

    /// ProductShippingClass initializer.
    ///
    public init(shippingClassID: Int64,
                siteID: Int64,
                name: String,
                slug: String,
                descriptionHTML: String?,
                count: Int64) {
        self.shippingClassID = shippingClassID
        self.siteID = siteID
        self.name = name
        self.slug = slug
        self.descriptionHTML = descriptionHTML
        self.count = count
    }

    /// Public initializer for ProductShippingClass.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductShippingClassDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)
        let descriptionHTML = try container.decodeIfPresent(String.self, forKey: .descriptionHTML)
        let count = try container.decode(Int64.self, forKey: .count)

        self.init(shippingClassID: shippingClassID,
                  siteID: siteID,
                  name: name,
                  slug: slug,
                  descriptionHTML: descriptionHTML,
                  count: count)
    }
}


/// Defines all of the ProductTag CodingKeys
///
private extension ProductShippingClass {
    enum CodingKeys: String, CodingKey {
        case shippingClassID = "id"
        case name
        case slug
        case descriptionHTML = "description"
        case count
    }
}


// MARK: - Equatable Conformance
//
extension ProductShippingClass: Equatable {
    public static func == (lhs: ProductShippingClass, rhs: ProductShippingClass) -> Bool {
        return lhs.shippingClassID == rhs.shippingClassID &&
            lhs.siteID == rhs.siteID &&
            lhs.name == rhs.name &&
            lhs.slug == rhs.slug &&
            lhs.descriptionHTML == rhs.descriptionHTML &&
            lhs.count == rhs.count
    }
}


// MARK: - Decoding Errors
//
enum ProductShippingClassDecodingError: Error {
    case missingSiteID
}
