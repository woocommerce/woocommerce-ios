import Yosemite

/// Provides data for product form UI on a `ProductVariation`, and handles product editing actions.
final class ProductVariationFormViewModel: ProductFormViewModelProtocol {
    typealias ProductModel = ProductVariation

    /// Emits product variation on change.
    var observableProduct: Observable<ProductVariation> {
        productVariationSubject
    }

    /// The latest product variation including potential edits.
    var productModel: ProductVariation {
        productVariation
    }

    /// Emits a boolean of whether the product variation has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> {
        isUpdateEnabledSubject
    }

    /// Creates actions available on the bottom sheet.
    private(set) var actionsFactory: ProductFormActionsFactoryProtocol

    /// Not applicable to product variation form
    private(set) var password: String? = nil

    /// Not applicable to product variation form
    private(set) var productName: Observable<String>? = nil

    private let productVariationSubject: PublishSubject<ProductVariation> = PublishSubject<ProductVariation>()
    private let isUpdateEnabledSubject: PublishSubject<Bool>

    /// The product variation before any potential edits; reset after a remote update.
    private var originalProductVariation: ProductVariation {
        didSet {
            productVariation = originalProductVariation
        }
    }

    /// The product variation with potential edits; reset after a remote update.
    private var productVariation: ProductVariation {
        didSet {
            guard productVariation != oldValue else {
                return
            }

            actionsFactory = ProductVariationFormActionsFactory(productVariation: productVariation)
            productVariationSubject.send(productVariation)
            isUpdateEnabledSubject.send(hasUnsavedChanges())
        }
    }

    private let productImageActionHandler: ProductImageActionHandler
    private let storesManager: StoresManager
    private var cancellable: ObservationToken?

    init(productVariation: ProductVariation,
         productImageActionHandler: ProductImageActionHandler,
         storesManager: StoresManager = ServiceLocator.stores) {
        self.productImageActionHandler = productImageActionHandler
        self.storesManager = storesManager
        self.originalProductVariation = productVariation
        self.productVariation = productVariation
        self.actionsFactory = ProductVariationFormActionsFactory(productVariation: productVariation)
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
        return productVariation != originalProductVariation || productImageActionHandler.productImageStatuses.hasPendingUpload
    }

    func hasProductChanged() -> Bool {
        return productVariation != originalProductVariation
    }

    func hasPasswordChanged() -> Bool {
        // no-op
        return false
    }
}

// MARK: - More menu
//
extension ProductVariationFormViewModel {
    func canEditProductSettings() -> Bool {
        return false
    }

    func canViewProductInStore() -> Bool {
        // no-op
        return false
    }
}

// MARK: Action handling
//
extension ProductVariationFormViewModel {
    func updateName(_ name: String) {
        // no-op: a variation's name is derived from its attributes and is not editable
    }

    func updateImages(_ images: [ProductImage]) {
        guard images.count <= 1 else {
            assertionFailure("Up to 1 image can be attached to a product variation.")
            return
        }
        productVariation = productVariation.copy(image: images.first)
    }

    func updateDescription(_ newDescription: String) {
        productVariation = productVariation.copy(description: newDescription)
    }

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        productVariation = productVariation.copy(dateOnSaleStart: dateOnSaleStart,
                                                 dateOnSaleEnd: dateOnSaleEnd,
                                                 regularPrice: regularPrice,
                                                 salePrice: salePrice,
                                                 taxStatusKey: taxStatus.rawValue,
                                                 taxClass: taxClass?.slug)
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool?,
                                 stockQuantity: Int64?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        productVariation = productVariation.copy(sku: sku,
                                                 manageStock: manageStock,
                                                 stockQuantity: stockQuantity,
                                                 stockStatus: stockStatus,
                                                 backordersKey: backordersSetting?.rawValue)
    }

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) {
        productVariation = productVariation.copy(weight: weight,
                                                 dimensions: dimensions,
                                                 shippingClass: shippingClass?.slug ?? "",
                                                 shippingClassID: shippingClass?.shippingClassID ?? 0)
    }

    func updateProductCategories(_ categories: [ProductCategory]) {
        // no-op
    }

    func updateProductTags(_ tags: [ProductTag]) {
        // no-op
    }

    func updateBriefDescription(_ briefDescription: String) {
        // no-op
    }

    func updateSKU(_ sku: String?) {
        // no-op
    }

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64]) {
        // no-op
    }

    func updateProductSettings(_ settings: ProductSettings) {
        // no-op
    }

    func updateExternalLink(externalURL: String?, buttonText: String) {
        // no-op
    }

    func updateStatus(_ isEnabled: Bool) {
        let status: ProductStatus = isEnabled ? .publish: .privateStatus
        productVariation = productVariation.copy(status: status)
    }
}

// MARK: Remote actions
//
extension ProductVariationFormViewModel {
    func updateProductRemotely(onCompletion: @escaping (Result<ProductVariation, ProductUpdateError>) -> Void) {
        let updateAction = ProductVariationAction.updateProductVariation(productVariation: productVariation) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let productVariation):
                self?.resetProductVariation(productVariation)
                onCompletion(.success(productVariation))
            }
        }
        storesManager.dispatch(updateAction)
    }

    private func resetProductVariation(_ productVariation: ProductVariation) {
        originalProductVariation = productVariation
        isUpdateEnabledSubject.send(hasUnsavedChanges())
    }
}

// MARK: Reset actions
//
extension ProductVariationFormViewModel {
    func resetPassword(_ password: String?) {
        // no-op
    }
}
