import Combine
import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// View model for `ProductDetailPreviewView`
///
final class ProductDetailPreviewViewModel: ObservableObject {

    @Published private(set) var isGeneratingDetails: Bool = false
    @Published private(set) var isSavingProduct: Bool = false
    @Published private(set) var generatedProduct: Product?

    @Published private(set) var productName: String
    @Published private(set) var productDescription: String?
    @Published private(set) var productType: String?
    @Published private(set) var productPrice: String?
    @Published private(set) var productCategories: String?
    @Published private(set) var productTags: String?
    @Published private(set) var productShippingDetails: String?
    @Published private(set) var errorState: ErrorState = .none

    /// Whether feedback banner for the generated text should be displayed.
    @Published private(set) var shouldShowFeedbackView = false

    private let productFeatures: String?

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let userDefaults: UserDefaults
    private let onProductCreated: (Product) -> Void

    private var currency: String
    private var currencyFormatter: CurrencyFormatter

    private var weightUnit: String?
    private var dimensionUnit: String?
    private let shippingValueLocalizer: ShippingValueLocalizer

    private var generatedProductSubscription: AnyCancellable?

    private lazy var categoryResultController: ResultsController<StorageProductCategory> = {
        let predicate = NSPredicate(format: "siteID = %lld", self.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductCategory.name, ascending: true)
        return ResultsController<StorageProductCategory>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    private lazy var tagResultController: ResultsController<StorageProductTag> = {
        let predicate = NSPredicate(format: "siteID = %lld", self.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductTag.name, ascending: true)
        return ResultsController<StorageProductTag>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    init(siteID: Int64,
         productName: String,
         productDescription: String?,
         productFeatures: String?,
         currency: String = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode),
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit,
         dimensionUnit: String? = ServiceLocator.shippingSettingsService.dimensionUnit,
         shippingValueLocalizer: ShippingValueLocalizer = DefaultShippingValueLocalizer(),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard,
         onProductCreated: @escaping (Product) -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.userDefaults = userDefaults
        self.onProductCreated = onProductCreated

        self.currency = currency
        self.currencyFormatter = currencyFormatter

        self.weightUnit = weightUnit
        self.dimensionUnit = dimensionUnit
        self.shippingValueLocalizer = shippingValueLocalizer

        self.productName = productName
        self.productDescription = productDescription
        self.productFeatures = productFeatures

        try? categoryResultController.performFetch()
        try? tagResultController.performFetch()
        observeGeneratedProduct()
    }

    @MainActor
    func generateProductDetails() async {
        shouldShowFeedbackView = false
        isGeneratingDetails = true
        errorState = .none
        do {
            async let language = try identifyLanguage()
            await fetchSettingsIfNeeded()
            let aiTone = userDefaults.aiTone(for: siteID)
            let product = try await generateProduct(language: language,
                                                    tone: aiTone)
            generatedProduct = product
            isGeneratingDetails = false
            shouldShowFeedbackView = true
            analytics.track(event: .ProductCreationAI.generateProductDetailsSuccess())
        } catch {
            analytics.track(event: .ProductCreationAI.generateProductDetailsFailed(error: error))
            DDLogError("⛔️ Error generating product with AI: \(error)")
            errorState = .generatingProduct
        }
    }

    @MainActor
    func saveProductAsDraft() async {
        analytics.track(event: .ProductCreationAI.saveAsDraftButtonTapped())
        guard let generatedProduct else {
            return
        }
        errorState = .none
        isSavingProduct = true
        do {
            let newProduct = try await saveProductRemotely(product: generatedProduct)
            analytics.track(event: .ProductCreationAI.saveAsDraftSuccess())
            onProductCreated(newProduct)
        } catch {
            DDLogError("⛔️ Error saving product with AI: \(error)")
            analytics.track(event: .ProductCreationAI.saveAsDraftFailed(error: error))
            errorState = .savingProduct
        }
        isSavingProduct = false
    }

    func handleFeedback(_ vote: FeedbackView.Vote) {
        analytics.track(event: .AIFeedback.feedbackSent(source: .productCreation,
                                                        isUseful: vote == .up))

        shouldShowFeedbackView = false
    }
}

// MARK: - Product details for preview
//
private extension ProductDetailPreviewViewModel {
    func observeGeneratedProduct() {
        generatedProductSubscription = $generatedProduct
            .compactMap { $0 }
            .sink { [weak self] product in
                guard let self else { return }
                self.updateProductDetails(with: product)
            }
    }

    func updateProductDetails(with product: Product) {
        productName = product.name
        productDescription = product.fullDescription ?? product.shortDescription
        productType = product.virtual ? Localization.virtualProductType : Localization.physicalProductType

        if let regularPrice = product.regularPrice, regularPrice.isNotEmpty {
            let formattedRegularPrice = currencyFormatter.formatAmount(regularPrice, with: currency) ?? ""
            productPrice = String.localizedStringWithFormat(Localization.regularPriceFormat, formattedRegularPrice)
        }

        productCategories = product.categoriesDescription()
        productTags = product.tagsDescription()
        updateShippingDetails(for: product)
    }

    func updateShippingDetails(for product: Product) {
        var shippingDetails = [String]()

        // Weight[unit]
        if let weight = product.weight, let weightUnit = weightUnit, !weight.isEmpty {
            let localizedWeight = shippingValueLocalizer.localized(shippingValue: weight) ?? weight
            shippingDetails.append(String.localizedStringWithFormat(Localization.weightFormat,
                                                                    localizedWeight, weightUnit))
        }

        // L x W x H[unit]
        let length = product.dimensions.length
        let width = product.dimensions.width
        let height = product.dimensions.height
        let dimensions = [length, width, height]
            .map({ shippingValueLocalizer.localized(shippingValue: $0) ?? $0 })
            .filter({ !$0.isEmpty })

        if let dimensionUnit = dimensionUnit,
           !dimensions.isEmpty {
            switch dimensions.count {
            case 1:
                let dimension = dimensions[0]
                shippingDetails.append(String.localizedStringWithFormat(Localization.oneDimensionFormat,
                                                                        dimension, dimensionUnit))
            case 2:
                let firstDimension = dimensions[0]
                let secondDimension = dimensions[1]
                shippingDetails.append(String.localizedStringWithFormat(Localization.twoDimensionsFormat,
                                                                        firstDimension, secondDimension, dimensionUnit))
            case 3:
                let firstDimension = dimensions[0]
                let secondDimension = dimensions[1]
                let thirdDimension = dimensions[2]
                shippingDetails.append(String.localizedStringWithFormat(Localization.fullDimensionsFormat,
                                                                        firstDimension, secondDimension, thirdDimension, dimensionUnit))
            default:
                break
            }
        }

        productShippingDetails = shippingDetails.isEmpty ? nil: shippingDetails.joined(separator: "\n")
    }
}

// MARK: - Site settings
//
private extension ProductDetailPreviewViewModel {
    func fetchSettingsIfNeeded() async {
        guard weightUnit == nil || dimensionUnit == nil else {
            return
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchGeneralSettings()
            }
            group.addTask {
                await self.fetchProductSiteSettings()
            }
        }

        currency = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
        currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        weightUnit = ServiceLocator.shippingSettingsService.weightUnit
        dimensionUnit = ServiceLocator.shippingSettingsService.dimensionUnit
    }

    @MainActor
    func fetchGeneralSettings() async {
        await withCheckedContinuation { continuation in
            let action = SettingAction.synchronizeGeneralSiteSettings(siteID: siteID) { error in
                if let error {
                    DDLogError("⛔️ Error synchronizing general site settings: \(error)")
                }
                continuation.resume()
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    func fetchProductSiteSettings() async {
        await withCheckedContinuation { continuation in
            let action = SettingAction.synchronizeProductSiteSettings(siteID: siteID) { error in
                if let error {
                    DDLogError("⛔️ Error synchronizing product site settings: \(error)")
                }
                continuation.resume()
            }
            stores.dispatch(action)
        }
    }
}

// MARK: Generating product
//
private extension ProductDetailPreviewViewModel {
    @MainActor
    func identifyLanguage() async throws -> String {
        do {
            let productInfo = {
                guard let features = productFeatures,
                      features.isNotEmpty else {
                    return productName
                }
                return productName + " " + features
            }()
            let language = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(ProductAction.identifyLanguage(siteID: siteID,
                                                               string: productInfo,
                                                               feature: .productCreation,
                                                               completion: { result in
                    continuation.resume(with: result)
                }))
            }
            return language
        } catch {
            throw IdentifyLanguageError.failedToIdentifyLanguage(underlyingError: error)
        }
    }

    @MainActor
    func generateProduct(language: String,
                           tone: AIToneVoice) async throws -> Product {
        let existingCategories = categoryResultController.fetchedObjects
        let existingTags = tagResultController.fetchedObjects

        let aiProduct = try await generateAIProduct(language: language,
                                                    tone: tone,
                                                    existingCategories: existingCategories,
                                                    existingTags: existingTags)

        let categories = existingCategories.filter({ aiProduct.categories.contains($0.name) })
        let tags = existingTags.filter({ aiProduct.tags.contains($0.name) })

        return Product(siteID: siteID,
                       aiProduct: aiProduct,
                       categories: categories,
                       tags: tags)
    }

    @MainActor
    func generateAIProduct(language: String,
                           tone: AIToneVoice,
                           existingCategories: [ProductCategory],
                           existingTags: [ProductTag]) async throws -> AIProduct {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.generateAIProduct(siteID: siteID,
                                                            productName: productName,
                                                            keywords: productFeatures ?? productDescription ?? "",
                                                            language: language,
                                                            tone: tone.rawValue,
                                                            currencySymbol: currency,
                                                            dimensionUnit: dimensionUnit,
                                                            weightUnit: weightUnit,
                                                            categories: existingCategories,
                                                            tags: existingTags,
                                                            completion: { result in
                continuation.resume(with: result)
            }))
        }
    }
}

// MARK: - Categories
//
private extension ProductDetailPreviewViewModel {
    @MainActor
    func synchronizeAllCategories() async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductCategoryAction.synchronizeProductCategories(siteID: siteID,
                                                                               fromPageNumber: Default.firstPageNumber,
                                                                               onCompletion: { result in
                continuation.resume()
            }))
        }
    }

    @MainActor
    func addCategories(_ names: [String]) async throws -> [ProductCategory] {
        guard names.isNotEmpty else {
            return []
        }
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductCategoryAction.addProductCategories(siteID: siteID,
                                                                       names: names,
                                                                       parentID: nil,
                                                                       onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }
}

// MARK: - Tags
//
private extension ProductDetailPreviewViewModel {
    @MainActor
    func synchronizeAllTags() async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductTagAction.synchronizeAllProductTags(siteID: siteID,
                                                                       onCompletion: { result in
                continuation.resume()
            }))
        }
    }

    @MainActor
    func addTags(_ names: [String]) async throws -> [ProductTag] {
        guard names.isNotEmpty else {
            return []
        }
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductTagAction.addProductTags(siteID: siteID,
                                                            tags: names,
                                                            onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }
}

// MARK: - Saving product
//
private extension ProductDetailPreviewViewModel {
    /// Saves the provided product remotely.
    ///
    @MainActor
    func saveProductRemotely(product: Product) async throws -> Product {
        try await withCheckedThrowingContinuation { continuation in
            let updateProductAction = ProductAction.addProduct(product: product) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let product):
                    continuation.resume(returning: product)
                }
            }
            stores.dispatch(updateProductAction)
        }
    }
}

// MARK: - Subtypes
//
extension ProductDetailPreviewViewModel {
    enum ErrorState: Equatable {
        case none
        case generatingProduct
        case savingProduct

        var errorMessage: String {
            switch self {
            case .none:
                return ""
            case .generatingProduct:
                return Localization.errorGenerating
            case .savingProduct:
                return Localization.errorSaving
            }
        }
    }
}

private extension ProductDetailPreviewViewModel {
    enum Localization {
        static let virtualProductType = NSLocalizedString("Virtual", comment: "Display label for simple virtual product type.")
        static let physicalProductType = NSLocalizedString("Physical", comment: "Display label for simple physical product type.")
        static let regularPriceFormat = NSLocalizedString("Regular price: %@", comment: "Format of the regular price on the Price Settings row")

        // Shipping
        static let weightFormat = NSLocalizedString("Weight: %1$@%2$@",
                                                    comment: "Format of the weight on the Shipping Settings row - weight[unit]")
        static let oneDimensionFormat = NSLocalizedString("Dimensions: %1$@%2$@",
                                                          comment: "Format of one dimension on the Shipping Settings row - dimension[unit]")
        static let twoDimensionsFormat = NSLocalizedString("Dimensions: %1$@ x %2$@ %3$@",
                                                           comment: "Format of 2 dimensions on the Shipping Settings row - dimension x dimension[unit]")
        static let fullDimensionsFormat = NSLocalizedString("Dimensions: %1$@ x %2$@ x %3$@ %4$@",
                                                            comment: "Format of all 3 dimensions on the Shipping Settings row - L x W x H[unit]")
        // Error messages
        static let errorGenerating = NSLocalizedString(
            "There was an error generating product details. Please try again.",
            comment: "Error message when generating product details fails on the add product with AI Preview screen."
        )
        static let errorSaving = NSLocalizedString(
            "There was an error saving product details. Please try again.",
            comment: "Error message when saving product as draft on the add product with AI Preview screen."
        )
    }
}

// MARK: - Constants
//
private extension ProductDetailPreviewViewModel {
    enum Default {
        public static let firstPageNumber = 1
    }
}
