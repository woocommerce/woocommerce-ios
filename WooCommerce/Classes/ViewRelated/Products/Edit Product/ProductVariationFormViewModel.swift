import Yosemite
import Observables

/// Provides data for product form UI on a `ProductVariation`, and handles product editing actions.
final class ProductVariationFormViewModel: ProductFormViewModelProtocol {

    typealias ProductModel = EditableProductVariationModel

    /// Emits product variation on change.
    var observableProduct: Observable<EditableProductVariationModel> {
        productVariationSubject
    }

    /// The latest product variation including potential edits.
    var productModel: EditableProductVariationModel {
        productVariation
    }

    /// The original product variation.
    var originalProductModel: EditableProductVariationModel {
        originalProductVariation
    }

    /// Emits a boolean of whether the product variation has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> {
        isUpdateEnabledSubject
    }

    /// Creates actions available on the bottom sheet.
    private(set) var actionsFactory: ProductFormActionsFactoryProtocol

    /// Product variation form only supports editing
    let formType: ProductFormType

    private let editable: Bool

    /// Not applicable to product variation form
    private(set) var password: String? = nil

    /// Not applicable to product variation form
    private(set) var productName: Observable<String>? = nil

    private let productVariationSubject: PublishSubject<EditableProductVariationModel> = PublishSubject<EditableProductVariationModel>()
    private let isUpdateEnabledSubject: PublishSubject<Bool>

    /// The product variation before any potential edits; reset after a remote update.
    private var originalProductVariation: EditableProductVariationModel {
        didSet {
            productVariation = originalProductVariation
        }
    }

    /// The product variation with potential edits; reset after a remote update.
    private var productVariation: EditableProductVariationModel {
        didSet {
            guard productVariation != oldValue else {
                return
            }

            actionsFactory = ProductVariationFormActionsFactory(productVariation: productVariation, editable: editable)
            productVariationSubject.send(productVariation)
            isUpdateEnabledSubject.send(hasUnsavedChanges())
        }
    }

    /// The action buttons that should be rendered in the navigation bar.
    var actionButtons: [ActionButtonType] {
        var buttons: [ActionButtonType] = {
            switch (formType, hasUnsavedChanges()) {
            case (.edit, true):
                return [.save]
            default:
                return []
            }
        }()

        if shouldShowMoreOptionsMenu() {
            buttons.append(.more)
        }

        return buttons
    }

    /// Assign this closure to get notified when the variation is deleted.
    ///
    var onVariationDeletion: ((ProductVariation) -> Void)?

    private let allAttributes: [ProductAttribute]
    private let parentProductSKU: String?
    private let productImageActionHandler: ProductImageActionHandler
    private let storesManager: StoresManager
    private var cancellable: ObservationToken?

    init(productVariation: EditableProductVariationModel,
         allAttributes: [ProductAttribute],
         parentProductSKU: String?,
         formType: ProductFormType,
         productImageActionHandler: ProductImageActionHandler,
         storesManager: StoresManager = ServiceLocator.stores) {
        self.allAttributes = allAttributes
        self.parentProductSKU = parentProductSKU
        self.productImageActionHandler = productImageActionHandler
        self.storesManager = storesManager
        self.originalProductVariation = productVariation
        self.productVariation = productVariation
        self.formType = formType
        self.editable = formType != .readonly
        self.actionsFactory = ProductVariationFormActionsFactory(productVariation: productVariation, editable: editable)
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
}

// MARK: - More menu
//
extension ProductVariationFormViewModel {
    /// Variations can't be published independently
    ///
    func canShowPublishOption() -> Bool {
        false
    }

    func canSaveAsDraft() -> Bool {
        false
    }

    func canEditProductSettings() -> Bool {
        false
    }

    func canViewProductInStore() -> Bool {
        false
    }

    func canShareProduct() -> Bool {
        false
    }

    func canDeleteProduct() -> Bool {
        formType == .edit
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
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(image: images.first),
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU)
    }

    func updateDescription(_ newDescription: String) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(description: newDescription),
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU)
    }

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(dateOnSaleStart: dateOnSaleStart,
                                                                                                                  dateOnSaleEnd: dateOnSaleEnd,
                                                                                                                  regularPrice: regularPrice,
                                                                                                                  salePrice: salePrice,
                                                                                                                  taxStatusKey: taxStatus.rawValue,
                                                                                                                  taxClass: taxClass?.slug),
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU)
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool?,
                                 stockQuantity: Decimal?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(sku: sku,
                                                                                                                  manageStock: manageStock,
                                                                                                                  stockQuantity: stockQuantity,
                                                                                                                  stockStatus: stockStatus,
                                                                                                                  backordersKey: backordersSetting?.rawValue),
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU)
    }

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: String?, shippingClassID: Int64?) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(weight: weight,
                                                 dimensions: dimensions,
                                                 shippingClass: shippingClass ?? "",
                                                 shippingClassID: shippingClassID ?? 0),
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU)
    }

    func updateProductType(productType: ProductType) {
        // no-op
    }

    func updateProductCategories(_ categories: [ProductCategory]) {
        // no-op
    }

    func updateProductTags(_ tags: [ProductTag]) {
        // no-op
    }

    func updateShortDescription(_ shortDescription: String) {
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
        ServiceLocator.analytics.track(.productVariationDetailViewStatusSwitchTapped)
        let status: ProductStatus = isEnabled ? .publish: .privateStatus
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(status: status),
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU)
    }

    func updateDownloadableFiles(downloadableFiles: [ProductDownload], downloadLimit: Int64, downloadExpiry: Int64) {
        // no-op
    }

    func updateLinkedProducts(upsellIDs: [Int64], crossSellIDs: [Int64]) {
        // no-op
    }

    func updateVariationAttributes(_ attributes: [ProductVariationAttribute]) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(attributes: attributes),
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU)
    }

    func updateProductVariations(from product: Product) {
        //no-op
    }
}

// MARK: Remote actions
//
extension ProductVariationFormViewModel {
    func saveProductRemotely(status: ProductStatus?, onCompletion: @escaping (Result<EditableProductVariationModel, ProductUpdateError>) -> Void) {
        let updateAction = ProductVariationAction.updateProductVariation(productVariation: productVariation.productVariation) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(let error):
                ServiceLocator.analytics.track(.productVariationDetailUpdateError, withError: error)
                onCompletion(.failure(error))
            case .success(let productVariation):
                ServiceLocator.analytics.track(.productVariationDetailUpdateSuccess)
                let model = EditableProductVariationModel(productVariation: productVariation,
                                                          allAttributes: self.allAttributes,
                                                          parentProductSKU: self.parentProductSKU)
                self.resetProductVariation(model)
                onCompletion(.success(model))
            }
        }
        storesManager.dispatch(updateAction)
    }

    func deleteProductRemotely(onCompletion: @escaping (Result<Void, ProductUpdateError>) -> Void) {
        let deleteAction = ProductVariationAction.deleteProductVariation(productVariation: productVariation.productVariation) { [weak self] result in
            switch result {
            case .success:
                if let self = self {
                    self.onVariationDeletion?(self.productVariation.productVariation)
                }
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
        storesManager.dispatch(deleteAction)
    }

    private func resetProductVariation(_ productVariation: EditableProductVariationModel) {
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
