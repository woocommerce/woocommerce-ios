import Yosemite

final class ProductFormViewModel {
    /// Emits product on change, except when the product name is the only change (`productName` is emitted for this case).
    var observableProduct: Observable<Product> {
        productSubject
    }

    /// Emits product name on change.
    var productName: Observable<String> {
        productNameSubject
    }

    /// Emits a boolean of whether the product has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> {
        isUpdateEnabledSubject
    }

    /// Creates actions available on the bottom sheet.
    private(set) var bottomSheetActionsFactory: ProductFormBottomSheetActionsFactory

    private let productSubject: PublishSubject<Product> = PublishSubject<Product>()
    private let productNameSubject: PublishSubject<String> = PublishSubject<String>()

    /// The product model before any potential edits; reset after a remote update.
    private var originalProduct: Product {
        didSet {
            product = originalProduct
        }
    }

    /// The product model with potential edits; reset after a remote update.
    private(set) var product: Product {
        didSet {
            defer {
                isUpdateEnabledSubject.send(hasUnsavedChanges())
            }

            if isNameTheOnlyChange(oldProduct: oldValue, newProduct: product) {
                productNameSubject.send(product.name)
                return
            }

            bottomSheetActionsFactory = ProductFormBottomSheetActionsFactory(product: product,
                                                                             isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                             isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
            productSubject.send(product)
        }
    }

    /// The product password, fetched in Product Settings
    private var originalPassword: String? {
        didSet {
            password = originalPassword
        }
    }

    private(set) var password: String?

    private var productUpdater: ProductUpdater {
        return product
    }

    private let isUpdateEnabledSubject: PublishSubject<Bool>

    private let currency: String
    private let productImageActionHandler: ProductImageActionHandler
    private let productUIImageLoader: ProductUIImageLoader
    private let isEditProductsRelease2Enabled: Bool
    private let isEditProductsRelease3Enabled: Bool

    init(product: Product,
         currency: String,
         productImageActionHandler: ProductImageActionHandler,
         productUIImageLoader: ProductUIImageLoader,
         isEditProductsRelease2Enabled: Bool,
         isEditProductsRelease3Enabled: Bool) {
        self.currency = currency
        self.productImageActionHandler = productImageActionHandler
        self.productUIImageLoader = productUIImageLoader
        self.isEditProductsRelease2Enabled = isEditProductsRelease2Enabled
        self.isEditProductsRelease3Enabled = isEditProductsRelease3Enabled
        self.originalProduct = product
        self.product = product
        self.bottomSheetActionsFactory = ProductFormBottomSheetActionsFactory(product: product,
                                                                              isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                              isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
        self.isUpdateEnabledSubject = PublishSubject<Bool>()
    }

    func hasUnsavedChanges() -> Bool {
        return product != originalProduct || productImageActionHandler.productImageStatuses.hasPendingUpload || password != originalPassword
    }

    func hasProductChanged() -> Bool {
        return product != originalProduct
    }

    func hasPasswordChanged() -> Bool {
        return password != nil && password != originalPassword
    }
}

// MARK: Action handling
//
extension ProductFormViewModel {
    func updateName(_ name: String) {
        product = productUpdater.nameUpdated(name: name)
    }

    func updatePassword(_ password: String?) {
        originalPassword = password
        isUpdateEnabledSubject.send(hasUnsavedChanges())
    }

    func updateImages(_ images: [ProductImage]) {
        product = productUpdater.imagesUpdated(images: images)
    }

    func updateDescription(_ newDescription: String) {
        product = productUpdater.descriptionUpdated(description: newDescription)
    }

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        product = productUpdater.priceSettingsUpdated(regularPrice: regularPrice,
                                                      salePrice: salePrice,
                                                      dateOnSaleStart: dateOnSaleStart,
                                                      dateOnSaleEnd: dateOnSaleEnd,
                                                      taxStatus: taxStatus,
                                                      taxClass: taxClass)
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool,
                                 stockQuantity: Int?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        product = productUpdater.inventorySettingsUpdated(sku: sku,
                                                          manageStock: manageStock,
                                                          soldIndividually: soldIndividually,
                                                          stockQuantity: stockQuantity,
                                                          backordersSetting: backordersSetting,
                                                          stockStatus: stockStatus)
    }

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) {
        product = productUpdater.shippingSettingsUpdated(weight: weight, dimensions: dimensions, shippingClass: shippingClass)
    }

    func updateBriefDescription(_ briefDescription: String) {
        product = productUpdater.briefDescriptionUpdated(briefDescription: briefDescription)
    }

    func updateProductSettings(_ settings: ProductSettings) {
        product = productUpdater.productSettingsUpdated(settings: settings)
    }
}

// MARK: Reset actions
//
extension ProductFormViewModel {
    func resetProduct(_ product: Product) {
        originalProduct = product
    }

    func resetPassword(_ password: String?) {
        originalPassword = password
    }
}

private extension ProductFormViewModel {
    func isNameTheOnlyChange(oldProduct: Product, newProduct: Product) -> Bool {
        let oldProductWithNewName = oldProduct.nameUpdated(name: newProduct.name)
        return oldProductWithNewName == newProduct && newProduct.name != oldProduct.name
    }
}
