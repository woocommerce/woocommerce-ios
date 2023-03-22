import Yosemite

/// Represents an editable data model based on `Product`.
final class EditableProductModel {
    let product: Product

    init(product: Product) {
        self.product = product
    }
}

extension EditableProductModel: ProductFormDataModel, TaxClassRequestable {

    var siteID: Int64 {
        product.siteID
    }

    var productID: Int64 {
        product.productID
    }

    var name: String {
        product.name
    }

    var description: String? {
        product.fullDescription
    }

    var shortDescription: String? {
        product.shortDescription
    }

    var permalink: String {
        product.permalink
    }

    var status: ProductStatus {
        product.productStatus
    }

    var virtual: Bool {
        product.virtual
    }

    var images: [ProductImage] {
        product.images
    }

    var regularPrice: String? {
        product.regularPrice
    }

    var salePrice: String? {
        product.salePrice
    }

    var dateOnSaleStart: Date? {
        product.dateOnSaleStart
    }

    var dateOnSaleEnd: Date? {
        product.dateOnSaleEnd
    }

    var taxStatusKey: String {
        product.taxStatusKey
    }

    var taxClass: String? {
        product.taxClass
    }

    var reviewsAllowed: Bool {
        product.reviewsAllowed
    }

    var averageRating: String {
        product.averageRating
    }

    var ratingCount: Int {
        product.ratingCount
    }

    var productType: ProductType {
        product.productType
    }

    var weight: String? {
        product.weight
    }

    var dimensions: ProductDimensions {
        product.dimensions
    }

    var shippingClass: String? {
        product.shippingClass
    }

    var shippingClassID: Int64 {
        product.shippingClassID
    }

    var sku: String? {
        product.sku
    }

    var manageStock: Bool {
        product.manageStock
    }

    var stockStatus: ProductStockStatus {
        product.productStockStatus
    }

    var stockQuantity: Decimal? {
        product.stockQuantity
    }

    var hasIntegerStockQuantity: Bool {
        product.hasIntegerStockQuantity
    }

    var backordersKey: String {
        product.backordersKey
    }

    var soldIndividually: Bool? {
        product.soldIndividually
    }

    var downloadableFiles: [ProductDownload] {
        product.downloads
    }

    var downloadable: Bool {
        product.downloadable
    }

    var downloadLimit: Int64 {
        product.downloadLimit
    }

    var downloadExpiry: Int64 {
        product.downloadExpiry
    }

    var upsellIDs: [Int64] {
        product.upsellIDs
    }

    var crossSellIDs: [Int64] {
        product.crossSellIDs
    }

    var hasAddOns: Bool {
        product.addOns.isNotEmpty
    }

    var bundledItems: [ProductBundleItem] {
        product.bundledItems
    }

    var bundleStockStatus: ProductStockStatus? {
        product.bundleStockStatus
    }

    var bundleStockQuantity: Int64? {
        product.bundleStockQuantity
    }

    var compositeComponents: [ProductCompositeComponent] {
        product.compositeComponents
    }

    func isStockStatusEnabled() -> Bool {
        // Only a variable product's stock status is not editable.
        productType != .variable
    }

    // Visibility logic

    func allowsMultipleImages() -> Bool {
        true
    }

    func isImageDeletionEnabled() -> Bool {
        true
    }

    func isShippingEnabled() -> Bool {
        product.downloadable == false && product.virtual == false
    }

    var existsRemotely: Bool {
        product.existsRemotely
    }

    /// Helper to determine if a product model is empty.
    /// We consider it as empty if its underlying product matches the `ProductFactory.createNewProduct` output.
    /// Additionally we don't take dates into consideration as we don't control their value when creating a product.
    ///
    func isEmpty() -> Bool {
        let simplifiedEditingEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.simplifyProductEditing)
        guard let emptyProduct = ProductFactory().createNewProduct(type: productType,
                                                                   isVirtual: virtual,
                                                                   siteID: siteID,
                                                                   status: simplifiedEditingEnabled ? .draft : .published) else {
            return false
        }

        let commonDate = Date()
        return emptyProduct.copy(date: commonDate, dateCreated: commonDate, dateModified: commonDate, dateOnSaleStart: commonDate, dateOnSaleEnd: commonDate) ==
               product.copy(date: commonDate, dateCreated: commonDate, dateModified: commonDate, dateOnSaleStart: commonDate, dateOnSaleEnd: commonDate)
    }
}

extension EditableProductModel: Equatable {
    static func ==(lhs: EditableProductModel, rhs: EditableProductModel) -> Bool {
        return lhs.product == rhs.product
    }
}
