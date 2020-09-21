import Yosemite

/// Provides data for product form UI, and handles product editing actions.
final class ProductFormViewModel: ProductFormViewModelProtocol {
    typealias ProductModel = EditableProductModel

    /// Emits product on change, except when the product name is the only change (`productName` is emitted for this case).
    var observableProduct: Observable<EditableProductModel> {
        productSubject
    }

    /// Emits product name on change.
    var productName: Observable<String>? {
        productNameSubject
    }

    /// Emits a boolean of whether the product has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> {
        isUpdateEnabledSubject
    }

    /// The latest product value.
    var productModel: EditableProductModel {
        product
    }

    /// The form type could change from .add to .edit after creation.
    private(set) var formType: ProductFormType

    /// Creates actions available on the bottom sheet.
    private(set) var actionsFactory: ProductFormActionsFactoryProtocol

    private let productSubject: PublishSubject<EditableProductModel> = PublishSubject<EditableProductModel>()
    private let productNameSubject: PublishSubject<String> = PublishSubject<String>()
    private let isUpdateEnabledSubject: PublishSubject<Bool>

    /// The product model before any potential edits; reset after a remote update.
    private var originalProduct: EditableProductModel {
        didSet {
            product = originalProduct
        }
    }

    /// The product model with potential edits; reset after a remote update.
    private var product: EditableProductModel {
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
    private let isEditProductsRelease3Enabled: Bool

    private var cancellable: ObservationToken?

    init(product: EditableProductModel,
         formType: ProductFormType,
         productImageActionHandler: ProductImageActionHandler,
         isEditProductsRelease3Enabled: Bool) {
        self.formType = formType
        self.productImageActionHandler = productImageActionHandler
        self.isEditProductsRelease3Enabled = isEditProductsRelease3Enabled
        self.originalProduct = product
        self.product = product
        self.actionsFactory = ProductFormActionsFactory(product: product,
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
}

// MARK: - More menu
//
extension ProductFormViewModel {
    func canEditProductSettings() -> Bool {
        return true
    }

    func canViewProductInStore() -> Bool {
        return originalProduct.product.productStatus == .publish
    }
}

// MARK: Action handling
//
extension ProductFormViewModel {
    func updateName(_ name: String) {
        product = EditableProductModel(product: product.product.copy(name: name))
    }

    func updateImages(_ images: [ProductImage]) {
        product = EditableProductModel(product: product.product.copy(images: images))
    }

    func updateDescription(_ newDescription: String) {
        product = EditableProductModel(product: product.product.copy(fullDescription: newDescription))
    }

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        product = EditableProductModel(product: product.product.copy(dateOnSaleStart: dateOnSaleStart,
                                                                     dateOnSaleEnd: dateOnSaleEnd,
                                                                     regularPrice: regularPrice,
                                                                     salePrice: salePrice,
                                                                     taxStatusKey: taxStatus.rawValue,
                                                                     taxClass: taxClass?.slug))
    }

    func updateProductType(productType: ProductType) {
        /// The property `manageStock` is set to `false` if the new `productType` is `affiliate`
        /// because it seems there is a small bug in APIs that doesn't allow us to change type from a product with
        /// manage stock enabled to external product type. More info: PR-2665
        ///
        var manageStock = product.product.manageStock
        if productType == .affiliate {
            manageStock = false
        }
        product = EditableProductModel(product: product.product.copy(productTypeKey: productType.rawValue, manageStock: manageStock))
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool?,
                                 stockQuantity: Int64?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        product = EditableProductModel(product: product.product.copy(sku: sku,
                                                                     manageStock: manageStock,
                                                                     stockQuantity: stockQuantity,
                                                                     stockStatusKey: stockStatus?.rawValue,
                                                                     backordersKey: backordersSetting?.rawValue,
                                                                     soldIndividually: soldIndividually))
    }

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: String?, shippingClassID: Int64?) {
        product = EditableProductModel(product: product.product.copy(weight: weight,
                                                                     dimensions: dimensions,
                                                                     shippingClass: shippingClass ?? "",
                                                                     shippingClassID: shippingClassID ?? 0))
    }

    func updateProductCategories(_ categories: [ProductCategory]) {
        product = EditableProductModel(product: product.product.copy(categories: categories))
    }

    func updateProductTags(_ tags: [ProductTag]) {
        product = EditableProductModel(product: product.product.copy(tags: tags))
    }

    func updateBriefDescription(_ briefDescription: String) {
        product = EditableProductModel(product: product.product.copy(briefDescription: briefDescription))
    }

    func updateSKU(_ sku: String?) {
        product = EditableProductModel(product: product.product.copy(sku: sku))
    }

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64]) {
        product = EditableProductModel(product: product.product.copy(groupedProducts: groupedProductIDs))
    }

    func updateProductSettings(_ settings: ProductSettings) {
        product = EditableProductModel(product: product.product.copy(slug: settings.slug,
                                                                     statusKey: settings.status.rawValue,
                                                                     featured: settings.featured,
                                                                     catalogVisibilityKey: settings.catalogVisibility.rawValue,
                                                                     virtual: settings.virtual,
                                                                     reviewsAllowed: settings.reviewsAllowed,
                                                                     purchaseNote: settings.purchaseNote,
                                                                     menuOrder: settings.menuOrder))
        password = settings.password
    }

    func updateExternalLink(externalURL: String?, buttonText: String) {
        product = EditableProductModel(product: product.product.copy(buttonText: buttonText, externalURL: externalURL))
    }

    func updateStatus(_ isEnabled: Bool) {
        // no-op: visibility is editable in product settings for `Product`
    }
}

// MARK: Remote actions
//
extension ProductFormViewModel {
    func updateProductRemotely(onCompletion: @escaping (Result<EditableProductModel, ProductUpdateError>) -> Void) {
        let remoteActionUseCase = ProductFormRemoteActionUseCase()
        switch formType {
        case .add:
            remoteActionUseCase.addProduct(product: product, password: password) { [weak self] result in
                switch result {
                case .failure(let error):
                    onCompletion(.failure(error))
                case .success(let data):
                    guard let self = self else {
                        return
                    }
                    self.formType = .edit
                    self.resetProduct(data.product)
                    self.resetPassword(data.password)
                    onCompletion(.success(data.product))
                }
            }
        case .edit:
            remoteActionUseCase.editProduct(product: product,
                                              originalProduct: originalProduct,
                                              password: password,
                                              originalPassword: originalPassword) { [weak self] result in
                                                guard let self = self else {
                                                    return
                                                }
                                                switch result {
                                                case .success(let data):
                                                    self.resetProduct(data.product)
                                                    self.resetPassword(data.password)
                                                    onCompletion(.success(data.product))
                                                case .failure(let error):
                                                    onCompletion(.failure(error))
                                                }
            }
        }
    }
}

// MARK: Reset actions
//
extension ProductFormViewModel {
    private func resetProduct(_ product: EditableProductModel) {
        originalProduct = product
    }

    func resetPassword(_ password: String?) {
        originalPassword = password
        isUpdateEnabledSubject.send(hasUnsavedChanges())
    }
}

private extension ProductFormViewModel {
    func isNameTheOnlyChange(oldProduct: EditableProductModel, newProduct: EditableProductModel) -> Bool {
        let oldProductWithNewName = EditableProductModel(product: oldProduct.product.copy(name: newProduct.name))
        return oldProductWithNewName == newProduct && newProduct.name != oldProduct.name
    }
}
