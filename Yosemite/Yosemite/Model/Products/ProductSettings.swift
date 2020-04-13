import Foundation


/// Represents a Product Settings Entity of editable data
///
public final class ProductSettings {
    public var status: ProductStatus
    public var featured: Bool
    public var catalogVisibility: ProductCatalogVisibility
    public var slug: String
    public var purchaseNote: String?

    public init(status: ProductStatus, featured: Bool, catalogVisibility: ProductCatalogVisibility, slug: String, purchaseNote: String?) {
        self.status = status
        self.featured = featured
        self.catalogVisibility = catalogVisibility
        self.slug = slug
        self.purchaseNote = purchaseNote
    }

    public convenience init(from product: Product) {
        self.init(status: product.productStatus, featured: product.featured, catalogVisibility: product.productCatalogVisibility, slug: product.slug, purchaseNote: product.purchaseNote)
    }
}

// MARK: - Equatable Conformance
//
extension ProductSettings: Equatable {
    public static func == (lhs: ProductSettings, rhs: ProductSettings) -> Bool {
        return lhs.status.rawValue == rhs.status.rawValue &&
            lhs.featured == rhs.featured &&
            lhs.catalogVisibility.rawValue == rhs.catalogVisibility.rawValue &&
            lhs.slug == rhs.slug &&
            lhs.purchaseNote == rhs.purchaseNote
    }
}
