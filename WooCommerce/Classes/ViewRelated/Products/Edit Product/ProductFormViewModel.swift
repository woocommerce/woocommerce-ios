import Combine
import Yosemite
import Experiments

import protocol Storage.StorageManagerType

/// Provides data for product form UI, and handles product editing actions.
final class ProductFormViewModel: ProductFormViewModelProtocol {
    typealias ProductModel = EditableProductModel

    /// Production variation ID only for Product Variation not for product
    var productionVariationID: Int64? = nil

    /// Emits product on change, except when the product name is the only change (`productName` is emitted for this case).
    var observableProduct: AnyPublisher<EditableProductModel, Never> {
        productSubject.eraseToAnyPublisher()
    }

    /// Emits product name on change.
    var productName: AnyPublisher<String, Never>? {
        productNameSubject.eraseToAnyPublisher()
    }

    /// Emits a boolean of whether the product has unsaved changes for remote update.
    var isUpdateEnabled: AnyPublisher<Bool, Never> {
        isUpdateEnabledSubject.eraseToAnyPublisher()
    }

    /// Emits a void value informing when there is a new variation price state available
    var newVariationsPrice: AnyPublisher<Void, Never> {
        newVariationsPriceSubject.eraseToAnyPublisher()
    }

    /// Emits a void value informing when Blaze eligibility is computed
    var blazeEligibilityUpdate: AnyPublisher<Void, Never> {
        blazeEligiblityUpdateSubject.eraseToAnyPublisher()
    }

    /// The latest product value.
    var productModel: EditableProductModel {
        product
    }

    /// The original product value.
    var originalProductModel: EditableProductModel {
        originalProduct
    }

    /// Whether the "Promote with Blaze" button should show Blaze intro view first or not when tapped.
    var shouldShowBlazeIntroView: Bool {
        blazeCampaignResultsController.isEmpty
    }

    /// The form type could change from .add to .edit after creation.
    private(set) var formType: ProductFormType

    /// Creates actions available on the bottom sheet.
    private(set) var actionsFactory: ProductFormActionsFactoryProtocol

    private let productSubject: PassthroughSubject<EditableProductModel, Never> = PassthroughSubject<EditableProductModel, Never>()
    private let productNameSubject: PassthroughSubject<String, Never> = PassthroughSubject<String, Never>()
    private let isUpdateEnabledSubject: PassthroughSubject<Bool, Never> = PassthroughSubject<Bool, Never>()
    private let newVariationsPriceSubject = PassthroughSubject<Void, Never>()
    private let blazeEligiblityUpdateSubject = PassthroughSubject<Void, Never>()

    private lazy var variationsResultsController = createVariationsResultsController()

    private var isEligibleForBlaze: Bool = false

    private var hasActiveBlazeCampaign: Bool = false

    /// Blaze campaign ResultsController.
    private lazy var blazeCampaignResultsController: ResultsController<StorageBlazeCampaignListItem> = {
        let predicate = NSPredicate(format: "siteID == %lld", product.siteID)
        let resultsController = ResultsController<StorageBlazeCampaignListItem>(storageManager: storageManager,
                                                                                matching: predicate,
                                                                                sortedBy: [])
        return resultsController
    }()

    /// Returns `true` if the `Add-ons` beta feature switch is enabled. `False` otherwise.
    /// Assigning this value will recreate the `actionsFactory` property.
    ///
    private var isAddOnsFeatureEnabled: Bool = false {
        didSet {
            updateActionsFactory()
        }
    }

    /// Returns `true` if the `linkedProductsPromo` banner should be displayed. `False` otherwise.
    /// Assigning this value will recreate the `actionsFactory` property.
    ///
    var isLinkedProductsPromoEnabled: Bool = false {
        didSet {
            updateActionsFactory()
        }
    }

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

            // Product changes ID when it is just created.
            if oldValue.productID != product.productID {
                updateVariationsResultsController()
            }

            updateFormTypeIfNeeded(oldProduct: oldValue.product)
            updateActionsFactory()
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

    /// The action buttons that should be rendered in the navigation bar.
    var actionButtons: [ActionButtonType] {
        // Figure out main action button first
        var buttons: [ActionButtonType] = {
            switch (formType,
                    originalProductModel.status,
                    productModel.status,
                    originalProduct.product.existsRemotely,
                    hasUnsavedChanges()) {
            case (.add, .published, .published, false, _): // New product with publish status
                return [.publish]

            case (.add, .published, _, false, _): // New product with a different status
                return [.save] // And publish in more

            case (.edit, .published, _, true, true): // Existing published product with changes
                return [.save]

            case (.edit, .published, _, true, false): // Existing published product with no changes
                return []

            case (.edit, _, _, true, true): // Any other existing product with changes
                return [.save] // And publish in more

            case (.edit, _, _, true, false): // Any other existing product with no changes
                return [.publish]

            case (.readonly, _, _, _, _): // Any product on readonly mode
                 return []

            default: // Impossible cases
                return []
            }
        }()

        // The `frame_nonce` value must be stored for the preview to be displayed
        if let site = stores.sessionManager.defaultSite,
           site.frameNonce.isNotEmpty,
            // Preview existing drafts or new products that can be saved as a draft
           canSaveAsDraft() || originalProductModel.status == .draft {
            buttons.insert(.preview, at: 0)
        }

        // Add more button if needed
        if shouldShowMoreOptionsMenu() {
            buttons.append(.more)
        }

        // Share button if up to one button is visible.
        if canShareProduct() && buttons.count <= 1 {
            buttons.insert(.share, at: 0)
        }

        return buttons
    }

    private let productImageActionHandler: ProductImageActionHandler
    private let productImagesUploader: ProductImageUploaderProtocol

    private var cancellable: AnyCancellable?

    private let stores: StoresManager

    private let storageManager: StorageManagerType

    private let analytics: Analytics

    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol

    private let favoriteProductsUseCase: FavoriteProductsUseCase

    /// Assign this closure to be notified when a new product is saved remotely
    ///
    var onProductCreated: (Product) -> Void = { _ in }

    /// Keeps a strong reference to the use case to wait for callback closures.
    ///
    private lazy var remoteActionUseCase = ProductFormRemoteActionUseCase(stores: stores)

    private let featureFlagService: FeatureFlagService

    init(product: EditableProductModel,
         formType: ProductFormType,
         productImageActionHandler: ProductImageActionHandler,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         productImagesUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
         analytics: Analytics = ServiceLocator.analytics,
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker(),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.formType = formType
        self.productImageActionHandler = productImageActionHandler
        self.originalProduct = product
        self.product = product
        self.actionsFactory = ProductFormActionsFactory(product: product, formType: formType)
        self.stores = stores
        self.storageManager = storageManager
        self.productImagesUploader = productImagesUploader
        self.analytics = analytics
        self.blazeEligibilityChecker = blazeEligibilityChecker
        self.favoriteProductsUseCase = FavoriteProductsUseCase(siteID: product.siteID)
        self.featureFlagService = featureFlagService

        self.cancellable = productImageActionHandler.addUpdateObserver(self) { [weak self] allStatuses in
            guard let self = self else { return }
            self.isUpdateEnabledSubject.send(self.hasUnsavedChanges())
        }

        queryAddOnsFeatureState()
        updateVariationsPriceState()
        configureResultsController()
        updateBlazeEligibility()
    }

    deinit {
        cancellable?.cancel()
    }

    func hasUnsavedChanges() -> Bool {
        let hasProductChangesExcludingImages = product.product.copy(images: []) != originalProduct.product.copy(images: [])
        let hasImageChanges = productImagesUploader
            .hasUnsavedChangesOnImages(key: .init(siteID: product.siteID,
                                                  productOrVariationID: .product(id: product.productID),
                                                  isLocalID: !product.existsRemotely),
                                       originalImages: originalProduct.images)
        return hasProductChangesExcludingImages || hasImageChanges || password != originalPassword || isNewTemplateProduct()
    }
}

// MARK: - More menu
//
extension ProductFormViewModel {

    /// Show publish button if the product can be published and the publish button is not already part of the action buttons.
    ///
    func canShowPublishOption() -> Bool {
        let newProduct = formType == .add && !originalProduct.product.existsRemotely
        let existingUnpublishedProduct = formType == .edit && originalProduct.product.existsRemotely && originalProduct.status != .published

        let productCanBePublished = newProduct || existingUnpublishedProduct
        let publishIsNotAlreadyVisible = !actionButtons.contains(.publish)

        return productCanBePublished && publishIsNotAlreadyVisible
    }

    func canSaveAsDraft() -> Bool {
        formType == .add && productModel.status != .draft
    }

    func canEditProductSettings() -> Bool {
        formType != .readonly
    }

    func canViewProductInStore() -> Bool {
        originalProduct.product.productStatus == .published && formType != .add
    }

    func canShareProduct() -> Bool {
        let isSitePublic = stores.sessionManager.defaultSite?.isPublic == true
        let productHasLinkToShare = URL(string: product.permalink) != nil
        return isSitePublic && formType != .add && productHasLinkToShare
    }

    func canFavoriteProduct() -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.favoriteProducts) else {
            return false
        }
        return formType != .add
    }

    /// Merchants can promote a product with Blaze if product and site are eligible, and there's no existing Blaze campaign for the product.
    func canPromoteWithBlaze() -> Bool {
        isEligibleForBlaze && !hasActiveBlazeCampaign
    }

    func canDeleteProduct() -> Bool {
        formType == .edit
    }

    func canDuplicateProduct() -> Bool {
        formType == .edit
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
            if product.subscription?.period != subscriptionPeriod || product.subscription?.periodInterval != subscriptionPeriodInterval {
                return "0"
            } else {
                return product.subscription?.length
            }
        }()

        let subscription = product.subscription?.copy(length: subscriptionLength,
                                                      period: subscriptionPeriod,
                                                      periodInterval: subscriptionPeriodInterval,
                                                      price: regularPrice,
                                                      signUpFee: subscriptionSignupFee)
        product = EditableProductModel(product: product.product.copy(dateOnSaleStart: dateOnSaleStart,
                                                                     dateOnSaleEnd: dateOnSaleEnd,
                                                                     regularPrice: regularPrice,
                                                                     salePrice: salePrice,
                                                                     taxStatusKey: taxStatus.rawValue,
                                                                     taxClass: taxClass?.slug,
                                                                     subscription: subscription))
    }

    func updateProductType(productType: BottomSheetProductType) {
        /// The property `manageStock` is set to `false` if the new `productType` is `affiliate`
        /// because it seems there is a small bug in APIs that doesn't allow us to change type from a product with
        /// manage stock enabled to external product type. More info: PR-2665
        ///
        var manageStock = product.product.manageStock
        if productType == .affiliate {
            manageStock = false
        }

        let subscription = productType == .subscription ? ProductSubscription.empty : nil
        product = EditableProductModel(product: product.product.copy(productTypeKey: productType.productType.rawValue,
                                                                     virtual: productType.isVirtual,
                                                                     manageStock: manageStock,
                                                                     subscription: subscription))
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool?,
                                 stockQuantity: Decimal?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        product = EditableProductModel(product: product.product.copy(sku: sku,
                                                                     manageStock: manageStock,
                                                                     stockQuantity: stockQuantity,
                                                                     stockStatusKey: stockStatus?.rawValue,
                                                                     backordersKey: backordersSetting?.rawValue,
                                                                     soldIndividually: soldIndividually))
    }

    func updateShippingSettings(weight: String?,
                                dimensions: ProductDimensions,
                                oneTimeShipping: Bool?,
                                shippingClass: String?,
                                shippingClassID: Int64?) {
        let subscription = product.subscription?.copy(oneTimeShipping: oneTimeShipping)
        product = EditableProductModel(product: product.product.copy(weight: weight,
                                                                     dimensions: dimensions,
                                                                     shippingClass: shippingClass ?? "",
                                                                     shippingClassID: shippingClassID ?? 0,
                                                                     subscription: subscription))
    }

    func updateProductCategories(_ categories: [ProductCategory]) {
        product = EditableProductModel(product: product.product.copy(categories: categories))
    }

    func updateProductTags(_ tags: [ProductTag]) {
        product = EditableProductModel(product: product.product.copy(tags: tags))
    }

    func updateShortDescription(_ shortDescription: String) {
        product = EditableProductModel(product: product.product.copy(shortDescription: shortDescription))
    }

    func updateSKU(_ sku: String?) {
        product = EditableProductModel(product: product.product.copy(sku: sku))
    }

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64]) {
        product = EditableProductModel(product: product.product.copy(groupedProducts: groupedProductIDs))
    }

    func updateProductSettings(_ settings: ProductSettings) {
        /// The property `manageStock` is set to `false` if the new `productType` is `affiliate`
        /// because it seems there is a small bug in APIs that doesn't allow us to change type from a product with
        /// manage stock enabled to external product type. More info: PR-2665
        ///
        var manageStock = product.product.manageStock
        if settings.productType == .affiliate {
            manageStock = false
        }

        product = EditableProductModel(product: product.product.copy(slug: settings.slug,
                                                                     productTypeKey: settings.productType.rawValue,
                                                                     statusKey: settings.status.rawValue,
                                                                     featured: settings.featured,
                                                                     catalogVisibilityKey: settings.catalogVisibility.rawValue,
                                                                     virtual: settings.virtual,
                                                                     downloadable: settings.downloadable,
                                                                     manageStock: manageStock,
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

    func updateDownloadableFiles(downloadableFiles: [ProductDownload], downloadLimit: Int64, downloadExpiry: Int64) {
        let newDownloadableStatus = product.downloadable ? true : downloadableFiles.isNotEmpty
        product = EditableProductModel(product: product.product.copy(downloadable: newDownloadableStatus,
                                                                     downloads: downloadableFiles,
                                                                     downloadLimit: downloadLimit,
                                                                     downloadExpiry: downloadExpiry))
    }

    func updateLinkedProducts(upsellIDs: [Int64], crossSellIDs: [Int64]) {
        product = EditableProductModel(product: product.product.copy(upsellIDs: upsellIDs,
                                                                     crossSellIDs: crossSellIDs))
    }

    func updateVariationAttributes(_ attributes: [ProductVariationAttribute]) {
        // no-op
    }

    /// Updates the original product variations(and attributes).
    /// This is needed because variations and attributes, remote updates, happen outside this view model and wee need a way to sync our original product.
    ///
    func updateProductVariations(from newProduct: Product) {
        // ProductID and statusKey could have changed, in case we had to create the product as a draft to create attributes or variations
        let newOriginalProduct = EditableProductModel(product: originalProduct.product.copy(productID: newProduct.productID,
                                                                                            statusKey: newProduct.statusKey,
                                                                                            attributes: newProduct.attributes,
                                                                                            variations: newProduct.variations))

        // Make sure the product is updated locally. Useful for screens that are observing the product or a list of products.
        updateStoredProduct(with: newOriginalProduct.product)

        // If the product doesn't have any pending changes, we can safely override the original product
        guard hasUnsavedChanges() else {
            return resetProduct(newOriginalProduct)
        }

        // If the product has pending changes, we need to override the `originalProduct` first and the `living product` later with a saved copy.
        // This is because, overriding `originalProduct` also overrides the `living product`.
        let productWithChanges = EditableProductModel(product: product.product.copy(productID: newProduct.productID,
                                                                                    statusKey: newProduct.statusKey,
                                                                                    attributes: newProduct.attributes,
                                                                                    variations: newProduct.variations))
        resetProduct(newOriginalProduct)
        product = productWithChanges
    }

    /// Fires a `Yosemite` action to update the product in our storage layer
    ///
    func updateStoredProduct(with newProduct: Product) {
        let action = ProductAction.replaceProductLocally(product: newProduct, onCompletion: {})
        stores.dispatch(action)
    }

    func updateSubscriptionFreeTrialSettings(trialLength: String, trialPeriod: SubscriptionPeriod) {
        let oneTimeShipping: Bool? = {
            guard let subscription = product.subscription else {
                return nil
            }

            // One time shipping can be turned on only if there is no Free trial
            guard trialLength.isEmpty || trialLength == "0" else {
                return false
            }

            return subscription.oneTimeShipping
        }()
        let subscription = product.subscription?.copy(trialLength: trialLength,
                                                      trialPeriod: trialPeriod,
                                                      oneTimeShipping: oneTimeShipping ?? nil)
        product = EditableProductModel(product: product.product.copy(subscription: subscription))
    }

    func updateSubscriptionExpirySettings(length: String) {
        let subscription = product.subscription?.copy(length: length)
        product = EditableProductModel(product: product.product.copy(subscription: subscription))
    }
}

// MARK: Remote actions
//
extension ProductFormViewModel {
    func saveProductRemotely(status: ProductStatus?, onCompletion: @escaping (Result<EditableProductModel, ProductUpdateError>) -> Void) {
        let productModelToSave: EditableProductModel = {
            guard let status = status, status != product.status else {
                return product
            }
            let productWithStatusUpdated = product.product.copy(statusKey: status.rawValue)
            return EditableProductModel(product: productWithStatusUpdated)
        }()

        switch formType {
        case .add:
            let productIDBeforeSave = productModel.productID
            remoteActionUseCase.addProduct(product: productModelToSave, password: password) { [weak self] result in
                switch result {
                case .failure(let error):
                    onCompletion(.failure(error))
                case .success(let data):
                    guard let self = self else {
                        return
                    }
                    self.resetProduct(data.product)
                    self.resetPassword(data.password)
                    self.replaceProductID(productIDBeforeSave: productIDBeforeSave)
                    self.saveProductImagesWhenNoneIsPendingUploadAnymore()
                    self.onProductCreated(data.product.product)
                    onCompletion(.success(data.product))
                }
            }
        case .edit:
            remoteActionUseCase.editProduct(product: productModelToSave,
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
                                                    self.saveProductImagesWhenNoneIsPendingUploadAnymore()
                                                case .failure(let error):
                                                    onCompletion(.failure(error))
                                                }
            }
        case .readonly:
            assertionFailure("Trying to save a product remotely in readonly mode")
        }
    }

    func duplicateProduct(onCompletion: @escaping (Result<ProductModel, ProductUpdateError>) -> Void) {

        remoteActionUseCase.duplicateProduct(originalProduct: product,
                                             password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let data):
                self.resetProduct(data.product)
                self.resetPassword(data.password)
                onCompletion(.success(data.product))
            }
        }
    }

    func deleteProductRemotely(onCompletion: @escaping (Result<Void, ProductUpdateError>) -> Void) {

        remoteActionUseCase.deleteProduct(product: product) { result in
            switch result {
            case .success:
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}

// MARK: Background image upload
//
private extension ProductFormViewModel {
    func replaceProductID(productIDBeforeSave: Int64) {
        productImagesUploader.replaceLocalID(siteID: product.siteID,
                                             localID: .product(id: productIDBeforeSave),
                                             remoteID: product.productID)
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore() {
        productImagesUploader
            .saveProductImagesWhenNoneIsPendingUploadAnymore(key: .init(siteID: product.siteID,
                                                                        productOrVariationID: .product(id: product.productID),
                                                                        isLocalID: !product.existsRemotely)) { [weak self] result in
                guard let self = self else { return }
            switch result {
            case .success(let images):
                let currentProduct = self.product
                self.resetProduct(.init(product: self.originalProduct.product.copy(images: images)))
                // Because `resetProduct` also internally updates the latest `product`, the `product` is set with the value before `resetProduct` to
                // retain any local changes.
                self.product = .init(product: currentProduct.product)
            case .failure:
                // If the product images update request fails, the update CTA visibility is refreshed again so that the merchant can save the
                // product images again along with any other potential local changes.
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
extension ProductFormViewModel {
    private func resetProduct(_ product: EditableProductModel) {
        originalProduct = product
        updateBlazeEligibility()
    }

    func resetPassword(_ password: String?) {
        originalPassword = password
        isUpdateEnabledSubject.send(hasUnsavedChanges())
    }
}

// MARK: Tracking
//
extension ProductFormViewModel {
    func trackProductFormLoaded() {
        let hasLinkedProducts = product.upsellIDs.isNotEmpty || product.crossSellIDs.isNotEmpty
        let hasMinMaxQuantityRules = product.hasQuantityRules
        analytics.track(event: WooAnalyticsEvent.ProductDetail.loaded(hasLinkedProducts: hasLinkedProducts,
                                                                      hasMinMaxQuantityRules: hasMinMaxQuantityRules,
                                                                      horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
    }
}

// MARK: Miscellaneous

private extension ProductFormViewModel {
    func isNameTheOnlyChange(oldProduct: EditableProductModel, newProduct: EditableProductModel) -> Bool {
        let oldProductWithNewName = EditableProductModel(product: oldProduct.product.copy(name: newProduct.name))
        return oldProductWithNewName == newProduct && newProduct.name != oldProduct.name
    }

    /// Updates the `newVariationsPriceSubject`and `actionsFactory` to the latest variations price information.
    /// Returns weather the variation
    ///
    func updateVariationsPriceState() {
        updateActionsFactory()
        newVariationsPriceSubject.send(())
    }

    /// Calculates the variations price state for the current fetched variations.
    ///
    func calculateVariationPriceState() -> ProductFormActionsFactory.VariationsPrice {
        // If there are no fetched variations we can't be sure of it's price state
        guard !variationsResultsController.isEmpty else {
            return .unknown
        }

        let someMissingPrice = variationsResultsController.fetchedObjects.contains { $0.regularPrice.isNilOrEmpty }
        return someMissingPrice ? .notSet : .set
    }

    /// Updates the internal `formType` when a product changes from new to a saved status.
    /// Currently needed when a new product was just created as a draft to allow creating attributes and variations.
    ///
    func updateFormTypeIfNeeded(oldProduct: Product) {
        guard !oldProduct.existsRemotely, product.product.existsRemotely else {
            return
        }

        formType = .edit
    }

    /// Reassigns the `variationsResultsController` with a newly created object.
    ///
    private func updateVariationsResultsController() {
        variationsResultsController = createVariationsResultsController()
    }

    /// Creates a variations results controller.
    ///
    private func createVariationsResultsController() -> ResultsController<StorageProductVariation> {
        let predicate = NSPredicate(format: "product.siteID = %ld AND product.productID = %ld", product.siteID, product.productID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductVariation.productVariationID, ascending: true)
        let controller = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])

        try? controller.performFetch()
        controller.onDidChangeContent = { [weak self] in
            self?.updateVariationsPriceState()
        }

        return controller
    }

    /// Helper to determine if the added/editted product comes as a new template product.
    /// We assume that a new template product is a product that:
    ///  - Doesn't have an `id` - has not been saved remotely
    ///  - Is not empty.
    ///
    private func isNewTemplateProduct() -> Bool {
        originalProduct.productID == .zero && !originalProduct.isEmpty()
    }
}

// MARK: Beta feature handling
//
private extension ProductFormViewModel {
    /// Query the latest `Add-ons` beta feature state.
    ///
    func queryAddOnsFeatureState() {
        let action = AppSettingsAction.loadOrderAddOnsSwitchState { [weak self] result in
            guard let self = self, case .success(let addOnsEnabled) = result else {
                return
            }
            self.isAddOnsFeatureEnabled = addOnsEnabled
        }
        stores.dispatch(action)
    }

    /// Recreates `actionsFactory` with the latest `product`, `formType`, `canPromoteWithBlaze` and `isAddOnsFeatureEnabled` information.
    ///
    func updateActionsFactory() {
        actionsFactory = ProductFormActionsFactory(product: product,
                                                   formType: formType,
                                                   canPromoteWithBlaze: canPromoteWithBlaze(),
                                                   addOnsFeatureEnabled: isAddOnsFeatureEnabled,
                                                   isLinkedProductsPromoEnabled: isLinkedProductsPromoEnabled,
                                                   variationsPrice: calculateVariationPriceState())
    }
}

private extension ProductFormViewModel {
    func updateBlazeEligibility() {
        guard formType == .edit else {
            isEligibleForBlaze = false
            return
        }
        Task { @MainActor in
            let isEligible = await blazeEligibilityChecker.isProductEligible(product: originalProduct, isPasswordProtected: password?.isNotEmpty == true)
            isEligibleForBlaze = isEligible
            updateActionsFactory()
            blazeEligiblityUpdateSubject.send()
        }
    }

    /// Performs initial fetch from storage and updates results.
    func configureResultsController() {
        blazeCampaignResultsController.onDidChangeContent = { [weak self] in
            self?.updateBlazeCampaignResult()

        }
        blazeCampaignResultsController.onDidResetContent = { [weak self] in
            self?.updateBlazeCampaignResult()
        }

        do {
            try blazeCampaignResultsController.performFetch()
            updateBlazeCampaignResult()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func updateBlazeCampaignResult() {
        hasActiveBlazeCampaign = hasBlazeCampaign()
    }
}

// MARK: Blaze
//
private extension ProductFormViewModel {
    /// Check whether there is already an existing campaign for the current Product, that also has one of these statuses:
    /// - pending,
    /// - scheduled, or
    /// - active.
    func hasBlazeCampaign() -> Bool {
        let campaigns = blazeCampaignResultsController.fetchedObjects
        return campaigns.contains(where: {
            ($0.productID == product.productID) &&
            ($0.status == .pending || $0.status == .scheduled || $0.status == .active)
        })
    }
}


// MARK: Favorite
//
extension ProductFormViewModel {
    func isFavorite() -> Bool {
        favoriteProductsUseCase.isFavorite(productID: product.productID)
    }

    func markAsFavorite() {
        favoriteProductsUseCase.markAsFavorite(productID: product.productID)
    }

    func removeFromFavorite() {
        favoriteProductsUseCase.removeFromFavorite(productID: product.productID)
    }
}
