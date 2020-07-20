import Foundation


/// Represents a Product Settings Entity of editable data
///
public final class ProductSettings {
    public var status: ProductStatus
    public var featured: Bool
    public var password: String?
    public var catalogVisibility: ProductCatalogVisibility
    public var reviewsAllowed: Bool
    public var slug: String
    public var purchaseNote: String?
    public var menuOrder: Int

    public init(status: ProductStatus,
                featured: Bool,
                password: String?,
                catalogVisibility: ProductCatalogVisibility,
                reviewsAllowed: Bool,
                slug: String,
                purchaseNote: String?,
                menuOrder: Int) {
        self.status = status
        self.featured = featured
        self.password = password
        self.catalogVisibility = catalogVisibility
        self.reviewsAllowed = reviewsAllowed
        self.slug = slug
        self.purchaseNote = purchaseNote
        self.menuOrder = menuOrder
    }

    public convenience init(from product: Product, password: String?) {
        self.init(status: product.productStatus,
                  featured: product.featured,
                  password: password,
                  catalogVisibility: product.productCatalogVisibility,
                  reviewsAllowed: product.reviewsAllowed,
                  slug: product.slug,
                  purchaseNote: product.purchaseNote,
                  menuOrder: product.menuOrder)
    }
}

// MARK: - Equatable Conformance
//
extension ProductSettings: Equatable {
    public static func == (lhs: ProductSettings, rhs: ProductSettings) -> Bool {
        return lhs.status.rawValue == rhs.status.rawValue &&
            lhs.featured == rhs.featured &&
            lhs.password == rhs.password &&
            lhs.catalogVisibility.rawValue == rhs.catalogVisibility.rawValue &&
            lhs.reviewsAllowed == rhs.reviewsAllowed &&
            lhs.slug == rhs.slug &&
            lhs.purchaseNote == rhs.purchaseNote &&
            lhs.menuOrder == rhs.menuOrder
    }
}
