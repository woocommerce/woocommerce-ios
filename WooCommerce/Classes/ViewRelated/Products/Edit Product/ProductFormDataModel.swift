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
    var virtual: Bool { get }
    var downloadable: Bool { get }
    var permalink: String { get }

    // Images
    var images: [ProductImage] { get }
    /// Whether the product model allows multiple images.
    func allowsMultipleImages() -> Bool

    // Price
    var regularPrice: String? { get }
    var salePrice: String? { get }
    var dateOnSaleStart: Date? { get }
    var dateOnSaleEnd: Date? { get }
    var taxStatusKey: String { get }
    var taxClass: String? { get }

    // Shipping
    var weight: String? { get }
    var dimensions: ProductDimensions { get }
    var shippingClass: String? { get }
    var shippingClassID: Int64 { get }

    // Inventory
    var sku: String? { get }
    var manageStock: Bool { get }
    var stockStatus: ProductStockStatus { get }
    var stockQuantity: Int64? { get }
    var backordersKey: String { get }
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

    /// Whether shipping settings are available for the product.
    var isShippingEnabled: Bool {
        downloadable == false && virtual == false
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

extension Product: ProductFormDataModel {
    var description: String? {
        fullDescription
    }

    var shortDescription: String? {
        briefDescription
    }

    var stockStatus: ProductStockStatus {
        productStockStatus
    }

    func allowsMultipleImages() -> Bool {
        true
    }
}

extension ProductVariation: ProductFormDataModel {
    var name: String {
        attributes.map({ $0.option }).joined(separator: " - ")
    }

    var shortDescription: String? {
        nil
    }

    var images: [ProductImage] {
        [image].compactMap { $0 }
    }

    func allowsMultipleImages() -> Bool {
        false
    }
}
