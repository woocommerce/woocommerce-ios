import Yosemite

/// Describes a data model that contains necessary properties for rendering a product form (`ProductFormViewController`).
protocol ProductFormDataModel {
    // General
    var siteID: Int64 { get }
    var productID: Int64 { get }
    var name: String { get }
    var description: String? { get }
    var shortDescription: String? { get }

    // Settings
    var permalink: String { get }
    var status: ProductStatus { get }
    var virtual: Bool { get }

    // Images
    var images: [ProductImage] { get }
    /// Whether the product model allows multiple images.
    func allowsMultipleImages() -> Bool
    /// Whether the product model's images can be deleted.
    /// TODO-2576: always allows image deletion when the API issue is fixed for removing an image from a product variation.
    func isImageDeletionEnabled() -> Bool

    // Price
    var regularPrice: String? { get }
    var salePrice: String? { get }
    var dateOnSaleStart: Date? { get }
    var dateOnSaleEnd: Date? { get }
    var taxStatusKey: String { get }
    var taxClass: String? { get }

    // Reviews
    var reviewsAllowed: Bool { get }
    var averageRating: String { get }
    var ratingCount: Int { get }

    // Product Type
    var productType: ProductType { get }

    // Shipping
    var weight: String? { get }
    var dimensions: ProductDimensions { get }
    var shippingClass: String? { get }
    var shippingClassID: Int64 { get }
    // Whether shipping settings are available for the product.
    func isShippingEnabled() -> Bool

    // Inventory
    var sku: String? { get }
    var manageStock: Bool { get }
    var stockStatus: ProductStockStatus { get }
    var stockQuantity: Int64? { get }
    var backordersKey: String { get }
    var soldIndividually: Bool? { get }
    // Whether stock status is available for the product.
    func isStockStatusEnabled() -> Bool

    // Product downloads
    var downloadable: Bool { get }
    var downloadableFiles: [ProductDownload] { get }
    var downloadLimit: Int64 { get }
    var downloadExpiry: Int64 { get }
}

// MARK: Helpers that can be derived from `ProductFormDataModel`
//
extension ProductFormDataModel {
    /// Returns the full description without the HTML tags and leading/trailing white spaces and new lines.
    var trimmedFullDescription: String? {
        guard let description = description else {
            return nil
        }
        return description.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns `ProductTaxStatus` given the raw value from `taxStatusKey` field.
    var productTaxStatus: ProductTaxStatus {
        ProductTaxStatus(rawValue: taxStatusKey)
    }

    /// Returns `ProductBackordersSetting` given the raw value from `backordersKey` field.
    var backordersSetting: ProductBackordersSetting {
        ProductBackordersSetting(rawValue: backordersKey)
    }
}
