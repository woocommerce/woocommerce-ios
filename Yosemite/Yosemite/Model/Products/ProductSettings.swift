import Foundation


/// Represents a Product Settings Entity of editable data
///
public final class ProductSettings {
    public var status: ProductStatus
    public var featured: Bool
    public var catalogVisibility: ProductCatalogVisibility

    public init(status: ProductStatus, featured: Bool, catalogVisibility: ProductCatalogVisibility) {
        self.status = status
        self.featured = featured
        self.catalogVisibility = catalogVisibility
    }
}
