import Combine
import Yosemite

/// Provides data for product form UI on a `ProductVariation`, and handles product editing actions.
final class ProductVariationFormViewModel: ProductFormViewModelProtocol {

    typealias ProductModel = EditableProductVariationModel

    /// Emits product variation on change.
    var observableProduct: AnyPublisher<EditableProductVariationModel, Never> {
        productVariationSubject.eraseToAnyPublisher()
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
    var isUpdateEnabled: AnyPublisher<Bool, Never> {
        isUpdateEnabledSubject.eraseToAnyPublisher()
    }

    /// Unused in variations but needed to satisfy protocol
    var blazeEligibilityUpdate: AnyPublisher<Void, Never> {
        Just(Void()).eraseToAnyPublisher()
    }

    /// Also unused in variations but needed to satisfy protocol
    var shouldShowBlazeIntroView = false

    /// The product variation ID
    var productionVariationID: Int64? {
        productVariation.productVariation.productVariationID
    }

    /// Emits a void value informing when there is a new variation price state available
    var newVariationsPrice: AnyPublisher<Void, Never> = PassthroughSubject<Void, Never>().eraseToAnyPublisher()

    /// Creates actions available on the bottom sheet.
    private(set) var actionsFactory: ProductFormActionsFactoryProtocol

    /// Product variation form only supports editing
    let formType: ProductFormType

    private let editable: Bool

    /// Not applicable to product variation form
    private(set) var password: String? = nil

    /// Not applicable to product variation form
    private(set) var productName: AnyPublisher<String, Never>? = nil

    private let productVariationSubject: PassthroughSubject<EditableProductVariationModel, Never> = PassthroughSubject<EditableProductVariationModel, Never>()
    private let isUpdateEnabledSubject: PassthroughSubject<Bool, Never>

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
    private let parentProductDisablesQuantityRules: Bool?
    private let productImageActionHandler: ProductImageActionHandlerProtocol
    private let storesManager: StoresManager
    private let productImagesUploader: ProductImageUploaderProtocol
    private var cancellable: AnyCancellable?

    init(productVariation: EditableProductVariationModel,
         allAttributes: [ProductAttribute],
         parentProductSKU: String?,
         parentProductDisablesQuantityRules: Bool?,
         formType: ProductFormType,
         productImageActionHandler: ProductImageActionHandlerProtocol,
         storesManager: StoresManager = ServiceLocator.stores,
         productImagesUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader) {
        self.allAttributes = allAttributes
        self.parentProductSKU = parentProductSKU
        self.parentProductDisablesQuantityRules = parentProductDisablesQuantityRules
        self.productImageActionHandler = productImageActionHandler
        self.storesManager = storesManager
        self.originalProductVariation = productVariation
        self.productVariation = productVariation
        self.formType = formType
        self.editable = formType != .readonly
        self.actionsFactory = ProductVariationFormActionsFactory(productVariation: productVariation, editable: editable)
        self.isUpdateEnabledSubject = PassthroughSubject<Bool, Never>()
        self.productImagesUploader = productImagesUploader
        self.cancellable = productImageActionHandler.addUpdateObserver(self) { [weak self] allStatuses in
            guard let self = self else { return }
            self.isUpdateEnabledSubject.send(self.hasUnsavedChanges())
        }
    }

    deinit {
        cancellable?.cancel()
    }

    func hasUnsavedChanges() -> Bool {
        let hasProductChangesExcludingImages =
        productVariation.productVariation.copy(image: .some(nil)) != originalProductVariation.productVariation.copy(image: .some(nil))
        let hasImageChanges = productImagesUploader
            .hasUnsavedChangesOnImages(key: .init(siteID: productVariation.siteID,
                                                  productOrVariationID:
                    .variation(productID: productVariation.productVariation.productID,
                               variationID: productVariation.productVariation.productVariationID),
                                                  isLocalID: !productVariation.existsRemotely),
                                       originalImages: originalProductVariation.images)
        return hasProductChangesExcludingImages || hasImageChanges
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
        originalProductVariation.productVariation.status == .published && formType != .add
    }

    func canShareProduct() -> Bool {
        let isSitePublic = storesManager.sessionManager.defaultSite?.visibility == .publicSite
        let productHasLinkToShare = URL(string: originalProductVariation.permalink) != nil
        return isSitePublic && formType != .add && productHasLinkToShare
    }

    func canPromoteWithBlaze() -> Bool {
        // Product variations are not supported in Blaze.
        false
    }

    func canDeleteProduct() -> Bool {
        formType == .edit
    }

    func canDuplicateProduct() -> Bool {
        false
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
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updateDescription(_ newDescription: String) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(description: newDescription),
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updatePriceSettings(regularPrice: String?,
                             subscriptionPeriod: SubscriptionPeriod?,
                             subscriptionPeriodInterval: String?,
                             subscriptionSignupFee: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        // Sets "Expire after" to "0" (i.e. Never expire)
        // if the subscription period or interval is changed
        let subscriptionLength: String? = {
            if productVariation.subscription?.period != subscriptionPeriod || productVariation.subscription?.periodInterval != subscriptionPeriodInterval {
                return "0"
            } else {
                return productVariation.subscription?.length
            }
        }()

        let subscription = productVariation.subscription?.copy(length: subscriptionLength,
                                                               period: subscriptionPeriod,
                                                               periodInterval: subscriptionPeriodInterval,
                                                               price: regularPrice,
                                                               signUpFee: subscriptionSignupFee)
        productVariation = EditableProductVariationModel(
            productVariation: productVariation.productVariation.copy(
                dateOnSaleStart: dateOnSaleStart,
                dateOnSaleEnd: dateOnSaleEnd,
                regularPrice: regularPrice,
                salePrice: salePrice,
                taxStatusKey: taxStatus.rawValue,
                taxClass: taxClass?.slug,
                subscription: subscription
            ),
            parentProductType: productVariation.productType,
            allAttributes: allAttributes,
            parentProductSKU: parentProductSKU,
            parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
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
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updateShippingSettings(weight: String?,
                                dimensions: ProductDimensions,
                                // `oneTimeShipping` is ignored as this setting is not applicable for variation
                                // this needs to be set on the parent product
                                oneTimeShipping: Bool?,
                                shippingClass: String?,
                                shippingClassID: Int64?) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(weight: weight,
                                                                                                                  dimensions: dimensions,
                                                                                                                  shippingClass: shippingClass ?? "",
                                                                                                                  shippingClassID: shippingClassID ?? 0),
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updateProductType(productType: BottomSheetProductType) {
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
        let status: ProductStatus = isEnabled ? .published: .privateStatus
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(status: status),
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updateDownloadableFiles(downloadableFiles: [ProductDownload], downloadLimit: Int64, downloadExpiry: Int64) {
        // no-op
    }

    func updateLinkedProducts(upsellIDs: [Int64], crossSellIDs: [Int64]) {
        // no-op
    }

    func updateVariationAttributes(_ attributes: [ProductVariationAttribute]) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(attributes: attributes),
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updateProductVariations(from product: Product) {
        //no-op
    }

    func updateSubscriptionFreeTrialSettings(trialLength: String, trialPeriod: SubscriptionPeriod) {
        let subscription = productVariation.subscription?.copy(trialLength: trialLength,
                                                               trialPeriod: trialPeriod)
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(subscription: subscription),
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updateSubscriptionExpirySettings(length: String) {
        let subscription = productVariation.subscription?.copy(length: length)
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(subscription: subscription),
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
    }

    func updateQuantityRules(minQuantity: String, maxQuantity: String, groupOf: String) {
        productVariation = EditableProductVariationModel(productVariation: productVariation.productVariation.copy(minAllowedQuantity: minQuantity,
                                                                                                                  maxAllowedQuantity: maxQuantity,
                                                                                                                  groupOfQuantity: groupOf),
                                                         parentProductType: productVariation.productType,
                                                         allAttributes: allAttributes,
                                                         parentProductSKU: parentProductSKU,
                                                         parentProductDisablesQuantityRules: parentProductDisablesQuantityRules)
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
                                                          parentProductType: self.productVariation.productType,
                                                          allAttributes: self.allAttributes,
                                                          parentProductSKU: self.parentProductSKU,
                                                          parentProductDisablesQuantityRules: self.parentProductDisablesQuantityRules)
                self.resetProductVariation(model)
                onCompletion(.success(model))
                self.saveProductVariationImageWhenUploaded()
            }
        }
        storesManager.dispatch(updateAction)
    }

    func duplicateProduct(onCompletion: @escaping (Result<EditableProductVariationModel, ProductUpdateError>) -> Void) {
        // no-op
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

    private func saveProductVariationImageWhenUploaded() {
        productImagesUploader
            .saveProductImagesWhenNoneIsPendingUploadAnymore(key: .init(siteID: productVariation.siteID,
                                                                        productOrVariationID:
                    .variation(productID: productVariation.productVariation.productID,
                               variationID: productVariation.productVariation.productVariationID),
                                                                        isLocalID: !productVariation.existsRemotely)) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let images):
                    let currentProduct = self.productVariation
                    self.resetProductVariation(.init(productVariation: self.originalProductVariation.productVariation.copy(image: images.first),
                                                     parentProductType: productVariation.productType,
                                                     allAttributes: self.allAttributes,
                                                     parentProductSKU: self.parentProductSKU,
                                                     parentProductDisablesQuantityRules: self.parentProductDisablesQuantityRules))
                    // Because `resetProductVariation` also internally updates the latest `productVariation`, the
                    // `productVariation` is set with the value before `resetProductVariation` to retain any local changes.
                    self.productVariation = .init(productVariation: currentProduct.productVariation,
                                                  parentProductType: productVariation.productType,
                                                  allAttributes: self.allAttributes,
                                                  parentProductSKU: self.parentProductSKU,
                                                  parentProductDisablesQuantityRules: self.parentProductDisablesQuantityRules)
                case .failure:
                    // If the variation image update request fails, the update CTA visibility is refreshed again so that the merchant can save the
                    // variation image again along with any other potential local changes.
                    self.isUpdateEnabledSubject.send(self.hasUnsavedChanges())
                }
            }
        // Updates the update CTA visibility after scheduling a save request when no images are pending upload anymore, so that the update CTA
        // isn't shown right after the save request from pending image upload.
        // The save request keeps track of the latest image statuses at the time of the call and their upload progress over time.
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

// MARK: Tracking
//
extension ProductVariationFormViewModel {
    func trackProductFormLoaded() {
        // no-op
    }
}
