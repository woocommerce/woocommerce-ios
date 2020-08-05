import Yosemite

/// Represents an editable data model based on `ProductVariation`.
final class EditableProductVariationModel {
    let productVariation: ProductVariation

    init(productVariation: ProductVariation) {
        self.productVariation = productVariation
    }
}

extension EditableProductVariationModel: ProductFormDataModel, TaxClassRequestable {
    var siteID: Int64 {
        productVariation.siteID
    }

    var productID: Int64 {
        productVariation.productID
    }

    var name: String {
        productVariation.attributes.map({ $0.option }).joined(separator: " - ")
    }

    var description: String? {
        productVariation.description
    }

    var shortDescription: String? {
        nil
    }

    var permalink: String {
        productVariation.permalink
    }

    var images: [ProductImage] {
        [productVariation.image].compactMap { $0 }
    }

    var regularPrice: String? {
        productVariation.regularPrice
    }

    var salePrice: String? {
        productVariation.salePrice
    }

    var dateOnSaleStart: Date? {
        productVariation.dateOnSaleStart
    }

    var dateOnSaleEnd: Date? {
        productVariation.dateOnSaleEnd
    }

    var taxStatusKey: String {
        productVariation.taxStatusKey
    }

    var taxClass: String? {
        productVariation.taxClass
    }

    var averageRating: String {
        "0.00"
    }

    var ratingCount: Int {
        0
    }
    var weight: String? {
        productVariation.weight
    }

    var dimensions: ProductDimensions {
        productVariation.dimensions
    }

    var shippingClass: String? {
        productVariation.shippingClass
    }

    var shippingClassID: Int64 {
        productVariation.shippingClassID
    }

    var sku: String? {
        productVariation.sku
    }

    var manageStock: Bool {
        productVariation.manageStock
    }

    var stockStatus: ProductStockStatus {
        productVariation.stockStatus
    }

    var stockQuantity: Int64? {
        productVariation.stockQuantity
    }

    var backordersKey: String {
        productVariation.backordersKey
    }

    var soldIndividually: Bool? {
        nil
    }

    // Visibility logic

    func allowsMultipleImages() -> Bool {
        false
    }

    func isImageDeletionEnabled() -> Bool {
        false
    }

    func isShippingEnabled() -> Bool {
        productVariation.downloadable == false && productVariation.virtual == false
    }
}

extension EditableProductVariationModel: Equatable {
    static func ==(lhs: EditableProductVariationModel, rhs: EditableProductVariationModel) -> Bool {
        return lhs.productVariation == rhs.productVariation
    }
}
