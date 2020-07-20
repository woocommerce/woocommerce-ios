import Yosemite

/// Provides data for product form UI, and handles product editing actions.
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
    private(set) var actionsFactory: ProductFormActionsFactory

    private let productSubject: PublishSubject<Product> = PublishSubject<Product>()
    private let productNameSubject: PublishSubject<String> = PublishSubject<String>()
    private let isUpdateEnabledSubject: PublishSubject<Bool>

    /// The product model before any potential edits; reset after a remote update.
    private var originalProduct: Product {
        didSet {
            product = originalProduct
        }
    }

    /// The product model with potential edits; reset after a remote update.
    private(set) var product: Product {
        didSet {
            guard product != oldValue else {
                return
            }

            defer {
                isUpdateEnabledSubject.send(hasUnsavedChanges())
            }

            if isNameTheOnlyChange(oldProduct: oldValue, newProduct: product) {
                productNameSubject.send(product.name)
                return
            }

            actionsFactory = ProductFormActionsFactory(product: product,
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

    private(set) var password: String? {
        didSet {
            if password != oldValue {
                isUpdateEnabledSubject.send(hasUnsavedChanges())
            }
        }
    }

    private let productImageActionHandler: ProductImageActionHandler
    private let isEditProductsRelease2Enabled: Bool
    private let isEditProductsRelease3Enabled: Bool

    private var cancellable: ObservationToken?

    init(product: Product,
         productImageActionHandler: ProductImageActionHandler,
         isEditProductsRelease2Enabled: Bool,
         isEditProductsRelease3Enabled: Bool) {
        self.productImageActionHandler = productImageActionHandler
        self.isEditProductsRelease2Enabled = isEditProductsRelease2Enabled
        self.isEditProductsRelease3Enabled = isEditProductsRelease3Enabled
        self.originalProduct = product
        self.product = product
        self.actionsFactory = ProductFormActionsFactory(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
        self.isUpdateEnabledSubject = PublishSubject<Bool>()

        self.cancellable = productImageActionHandler.addUpdateObserver(self) { [weak self] allStatuses in
            if allStatuses.productImageStatuses.hasPendingUpload {
                self?.isUpdateEnabledSubject.send(true)
            }
        }
    }

    deinit {
        cancellable?.cancel()
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

    func canViewProductInStore() -> Bool {
        return originalProduct.productStatus == .publish
    }
}

// MARK: Action handling
//
extension ProductFormViewModel {
    func updateName(_ name: String) {
        product = product.copy(name: name)
    }

    func updateImages(_ images: [ProductImage]) {
        product = product.copy(images: images)
    }

    func updateDescription(_ newDescription: String) {
        product = product.copy(fullDescription: newDescription)
    }

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        product = product.copy(dateOnSaleStart: dateOnSaleStart,
                               dateOnSaleEnd: dateOnSaleEnd,
                               regularPrice: regularPrice,
                               salePrice: salePrice,
                               taxStatusKey: taxStatus.rawValue,
                               taxClass: taxClass?.slug)
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool,
                                 stockQuantity: Int?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        product = product.copy(sku: sku,
                               manageStock: manageStock,
                               stockQuantity: stockQuantity,
                               stockStatusKey: stockStatus?.rawValue,
                               backordersKey: backordersSetting?.rawValue,
                               soldIndividually: soldIndividually)
    }

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) {
        product = product.copy(weight: weight,
                               dimensions: dimensions,
                               shippingClass: shippingClass?.slug ?? "",
                               shippingClassID: shippingClass?.shippingClassID ?? 0,
                               productShippingClass: shippingClass)
    }

    func updateProductCategories(_ categories: [ProductCategory]) {
        product = product.copy(categories: categories)
    }

    func updateProductTags(_ tags: [ProductTag]) {
        product = product.copy(tags: tags)
    }

    func updateBriefDescription(_ briefDescription: String) {
        product = product.copy(briefDescription: briefDescription)
    }

    func updateSKU(_ sku: String?) {
        product = product.copy(sku: sku)
    }

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64]) {
        product = product.copy(groupedProducts: groupedProductIDs)
    }

    func updateProductSettings(_ settings: ProductSettings) {
        product = product.copy(slug: settings.slug,
                               statusKey: settings.status.rawValue,
                               featured: settings.featured,
                               catalogVisibilityKey: settings.catalogVisibility.rawValue,
                               virtual: settings.virtual,
                               reviewsAllowed: settings.reviewsAllowed,
                               purchaseNote: settings.purchaseNote,
                               menuOrder: settings.menuOrder)
        password = settings.password
    }

    func updateExternalLink(externalURL: String?, buttonText: String) {
        product = product.copy(buttonText: buttonText, externalURL: externalURL)
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
        isUpdateEnabledSubject.send(hasUnsavedChanges())
    }
}

private extension ProductFormViewModel {
    func isNameTheOnlyChange(oldProduct: Product, newProduct: Product) -> Bool {
        let oldProductWithNewName = oldProduct.copy(name: newProduct.name)
        return oldProductWithNewName == newProduct && newProduct.name != oldProduct.name
    }
}
