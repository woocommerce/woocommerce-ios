import Combine
import Foundation
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// View model for `ProductDetailPreviewView`
///
final class ProductDetailPreviewViewModel: ObservableObject {

    @Published private(set) var isGeneratingDetails: Bool = false
    @Published private(set) var generatedProduct: Product?

    @Published private(set) var productName: String
    @Published private(set) var productDescription: String?
    @Published private(set) var productType: String?
    @Published private(set) var productPrice: String?
    @Published private(set) var productCategories: String?
    @Published private(set) var productTags: String?
    @Published private(set) var productShippingDetails: String?
    @Published private(set) var errorMessage: String?

    private let productFeatures: String?
    private let packagingImage: MediaPickerImage?

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let userDefaults: UserDefaults

    private let currency: String
    private let currencyFormatter: CurrencyFormatter

    private let weightUnit: String?
    private let dimensionUnit: String?
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
         packagingImage: MediaPickerImage? = nil,
         currency: String = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode),
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit,
         dimensionUnit: String? = ServiceLocator.shippingSettingsService.dimensionUnit,
         shippingValueLocalizer: ShippingValueLocalizer = DefaultShippingValueLocalizer(),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.userDefaults = userDefaults

        self.currency = currency
        self.currencyFormatter = currencyFormatter

        self.weightUnit = weightUnit
        self.dimensionUnit = dimensionUnit
        self.shippingValueLocalizer = shippingValueLocalizer

        self.productName = productName
        self.productDescription = productDescription
        self.productFeatures = productFeatures
        self.packagingImage = packagingImage

        try? categoryResultController.performFetch()
        try? tagResultController.performFetch()
        observeGeneratedProduct()
    }

    @MainActor
    func generateProductDetails() async {
        isGeneratingDetails = true
        errorMessage = nil
        do {
            let language = try await identifyLanguage()
            let aiTone = userDefaults.aiTone(for: siteID)
            let product = try await generateProduct(language: language,
                                                    tone: aiTone)
            generatedProduct = product
        } catch {
            errorMessage = error.localizedDescription
            // TODO: Error handling
        }
        isGeneratingDetails = false
    }

    func saveProductAsDraft() {
        // TODO
    }

    func handleFeedback(_ vote: FeedbackView.Vote) {
        // TODO
    }
}

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
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.generateProduct(siteID: siteID,
                                                          productName: productName,
                                                          keywords: productFeatures ?? "",
                                                          language: language,
                                                          tone: tone.rawValue,
                                                          currencySymbol: currency,
                                                          dimensionUnit: dimensionUnit,
                                                          weightUnit: weightUnit,
                                                          categories: categoryResultController.fetchedObjects,
                                                          tags: tagResultController.fetchedObjects,
                                                          completion: { result in
                continuation.resume(with: result)
            }))
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
    }
}

private enum IdentifyLanguageError: Error {
    case failedToIdentifyLanguage(underlyingError: Error)
}
