import Yosemite

/// Represents an editable data model based on `ProductVariation`.
final class EditableProductVariationModel {
    let productVariation: ProductVariation

    let allAttributes: [ProductAttribute]

    private lazy var variationAttributes: [VariationAttributeViewModel] = {
        return generateVariationAttributes(productVariationAttributes: productVariation.attributes, allAttributes: allAttributes)
    }()

    init(productVariation: ProductVariation, allAttributes: [ProductAttribute], parentProductSKU: String?) {
        self.allAttributes = allAttributes

        // API sets a variation's SKU to be its parent product's SKU by default.
        // However, variation API update will fail if we send the variation's SKU as its parent product's SKU (duplicate SKU error).
        // As a workaround, we set a variation's SKU to nil if it has the same SKU as its parent product during initialization.
        let sku = parentProductSKU == productVariation.sku ? nil: productVariation.sku
        self.productVariation = productVariation.copy(sku: sku)
    }
}

private extension EditableProductVariationModel {

    func generateVariationAttributes(productVariationAttributes: [ProductVariationAttribute],
                                     allAttributes: [ProductAttribute]) -> [VariationAttributeViewModel] {
        return allAttributes
            .sorted(by: { (lhs, rhs) -> Bool in
                lhs.position < rhs.position
            })
            .map { attribute -> VariationAttributeViewModel in
            guard let variationAttribute = productVariation.attributes.first(where: { $0.id == attribute.attributeID && $0.name == attribute.name }) else {
                return VariationAttributeViewModel(name: attribute.name)
            }
            return VariationAttributeViewModel(productVariationAttribute: variationAttribute)
        }
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
        variationAttributes.map { $0.nameOrValue }.joined(separator: " - ")
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

    var status: ProductStatus {
        productVariation.status
    }

    var virtual: Bool {
        productVariation.virtual
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

    var reviewsAllowed: Bool {
        false
    }

    var averageRating: String {
        "0.00"
    }

    var ratingCount: Int {
        0
    }

    var productType: ProductType {
        .variable
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

    var stockQuantity: Decimal? {
        productVariation.stockQuantity
    }

    var hasIntegerStockQuantity: Bool {
        productVariation.hasIntegerStockQuantity
    }

    var backordersKey: String {
        productVariation.backordersKey
    }

    var soldIndividually: Bool? {
        nil
    }

    func isStockStatusEnabled() -> Bool {
        true
    }

    var downloadable: Bool {
        productVariation.downloadable
    }

    var downloadableFiles: [ProductDownload] {
        productVariation.downloads
    }

    var downloadLimit: Int64 {
        productVariation.downloadLimit
    }

    var downloadExpiry: Int64 {
        productVariation.downloadExpiry
    }

    var upsellIDs: [Int64] {
        []
    }

    var crossSellIDs: [Int64] {
        []
    }

    // Visibility logic

    func allowsMultipleImages() -> Bool {
        false
    }

    func isImageDeletionEnabled() -> Bool {
        true
    }

    func isShippingEnabled() -> Bool {
        productVariation.downloadable == false && productVariation.virtual == false
    }
}

extension EditableProductVariationModel {
    /// Whether the variation is enabled based on its status.
    var isEnabled: Bool {
        switch status {
        case .publish:
            return true
        case .privateStatus:
            return false
        default:
            DDLogError("Unexpected product variation status: \(status)")
            return false
        }
    }

    /// Whether the variation is enabled but doesn't have a price so that it is still not visible.
    var isEnabledAndMissingPrice: Bool {
        isEnabled && regularPrice.isNilOrEmpty
    }
}

extension EditableProductVariationModel: Equatable {
    static func ==(lhs: EditableProductVariationModel, rhs: EditableProductVariationModel) -> Bool {
        return lhs.productVariation == rhs.productVariation
    }
}
