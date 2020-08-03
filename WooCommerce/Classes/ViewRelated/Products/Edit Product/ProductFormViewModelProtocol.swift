import Yosemite

/// A view model for `ProductFormViewController` to add/edit a generic product model (e.g. `Product` or `ProductVariation`).
///
protocol ProductFormViewModelProtocol {
    associatedtype ProductModel: ProductFormDataModel & TaxClassRequestable

    /// Emits product on change, except when the product name is the only change (`productName` is emitted for this case).
    var observableProduct: Observable<ProductModel> { get }

    /// Emits product name on change. If the name is not editable (e.g. when the product model is `ProductVariation`), `nil` is returned.
    var productName: Observable<String>? { get }

    /// Emits a boolean of whether the product has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> { get }

    /// Creates actions available on the bottom sheet.
    var actionsFactory: ProductFormActionsFactoryProtocol { get }

    /// The latest product value.
    var productModel: ProductModel { get }

    /// The latest product password, if the product is password protected.
    var password: String? { get }

    // Unsaved changes

    func hasUnsavedChanges() -> Bool

    func hasProductChanged() -> Bool

    func hasPasswordChanged() -> Bool

    // More menu

    func canEditProductSettings() -> Bool

    func canViewProductInStore() -> Bool

    // Update actions

    func updateName(_ name: String)

    func updateImages(_ images: [ProductImage])

    func updateDescription(_ newDescription: String)

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?)

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool?,
                                 stockQuantity: Int64?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?)

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?)

    func updateProductCategories(_ categories: [ProductCategory])

    func updateProductTags(_ tags: [ProductTag])

    func updateBriefDescription(_ briefDescription: String)

    func updateSKU(_ sku: String?)

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64])

    func updateProductSettings(_ settings: ProductSettings)

    func updateExternalLink(externalURL: String?, buttonText: String)

    func updateVisibility(_ isVisible: Bool)

    // Remote action

    func updateProductRemotely(onCompletion: @escaping (Result<ProductModel, ProductUpdateError>) -> Void)

    // Reset action

    func resetPassword(_ password: String?)
}
