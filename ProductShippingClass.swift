// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation


/// Represents a ProductShippingClass entity.
///
internal class ProductShippingClass: Decodable {
    internal let count: Int64
    internal let descriptionHTML: String?
    internal let name: String
    internal let shippingClassID: Int64
    internal let siteID: Int64
    internal let slug: String

    /// ProductShippingClass initializer.
    ///
    public init(count: Int64,
                descriptionHTML: String?,
                name: String,
                shippingClassID: Int64,
                siteID: Int64,
                slug: String) {
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
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let count = try container.decode(Int64.self, forKey: .count)
        let descriptionHTML = try container.decodeIfPresent(String.self, forKey: .descriptionHTML)
        let name = try container.decode(String.self, forKey: .name)
        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)
        let siteID = try container.decode(Int64.self, forKey: .siteID)
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
        case descriptionHTML
        case name
        case shippingClassID
        case siteID
        case slug
    }
}


// MARK: - Equatable Conformance
//
extension ProductShippingClass: Equatable {
    public static func == (lhs: ProductShippingClass, rhs: ProductShippingClass) -> Bool {
        return lhs.count == rhs.count
            lhs.descriptionHTML == rhs.descriptionHTML
            lhs.name == rhs.name
            lhs.shippingClassID == rhs.shippingClassID
            lhs.siteID == rhs.siteID
            lhs.slug == rhs.slug
    }
}


