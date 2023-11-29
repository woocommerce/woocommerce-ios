import Foundation

import Yosemite
import Combine
import WooFoundation

/// Configuration of a bundled order item from the configuration UI. It contains necessary information to save the configuration remotely.
struct BundledProductConfiguration: Equatable {
    enum ProductOrVariation: Equatable {
        case product(id: Int64)
        case variation(productID: Int64, variationID: Int64, attributes: [ProductVariationAttribute])
    }

    let bundledItemID: Int64

    let productOrVariation: ProductOrVariation

    let quantity: Decimal

    /// `nil` when it's not optional.
    let isOptionalAndSelected: Bool?
}

/// View model for `ConfigurableBundleProductView`.
final class ConfigurableBundleProductViewModel: ObservableObject, Identifiable {
    @Published private(set) var bundleItemViewModels: [ConfigurableBundleItemViewModel] = []

    // TODO: 10428 - only enable configure CTA when all bundle items are configured
    @Published private(set) var isConfigureEnabled: Bool = true

    @Published private(set) var validationErrorMessage: String?
    @Published private(set) var loadProductsErrorMessage: String?

    /// View models for placeholder rows.
    let placeholderItemViewModels: [ConfigurableBundleItemViewModel]

    /// Closure invoked when the configure CTA is tapped to submit the configuration.
    /// If there are no changes to the configuration, the closure is not invoked.
    let onConfigure: (_ configurations: [BundledProductConfiguration]) -> Void

    /// Used to check if there are any outstanding changes to the configuration when submitting the form.
    /// This is set when the `bundleItemViewModels` are set.
    private var initialConfigurations: [BundledProductConfiguration] = []

    private let product: Product
    private let orderItem: OrderItem?
    private let childItems: [OrderItem]
    private let stores: StoresManager
    private let analytics: Analytics

    /// - Parameters:
    ///   - product: Bundle product in an order item.
    ///   - orderItem: Pre-existing order item of the bundle product.
    ///   - childItems: Pre-existing bundled order items.
    ///   - stores: For dispatching actions.
    ///   - onConfigure: Invoked when the configuration is confirmed.
    init(product: Product,
         orderItem: OrderItem? = nil,
         childItems: [OrderItem] = [],
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onConfigure: @escaping (_ configurations: [BundledProductConfiguration]) -> Void) {
        self.product = product
        self.orderItem = orderItem
        self.childItems = childItems
        self.stores = stores
        self.analytics = analytics
        self.onConfigure = onConfigure
        // The content does not matter because the text in placeholder rows is redacted.
        placeholderItemViewModels = [Int64](0..<3).map { _ in
                .init(bundleItem: .init(bundledItemID: 0,
                                        productID: 0,
                                        menuOrder: 0,
                                        title: "   ",
                                        stockStatus: .inStock,
                                        minQuantity: 0,
                                        maxQuantity: nil,
                                        defaultQuantity: 0,
                                        isOptional: true,
                                        overridesVariations: false,
                                        allowedVariations: [],
                                        overridesDefaultVariationAttributes: false,
                                        defaultVariationAttributes: [],
                                        pricedIndividually: false),
                      product: product,
                      variableProductSettings: nil,
                      existingParentOrderItem: nil,
                      existingOrderItem: nil)
        }

        loadProductsAndCreateItemViewModels()
    }

    /// Validates the bundle configuration of all bundled items.
    /// - Returns: A boolean that indicates whether the configuration is valid.
    func validate() -> Bool {
        validationErrorMessage = nil

        guard validateBundleSize() else {
            return false
        }

        guard !bundleItemViewModels.map({ $0.validate() }).contains(false) else {
            return false
        }

        return true
    }

    /// Completes the bundle configuration and triggers the configuration callback.
    func configure() {
        analytics.track(event: .Orders.orderFormBundleProductConfigurationSaveTapped())
        let configurations: [BundledProductConfiguration] = bundleItemViewModels.compactMap {
            $0.toConfiguration
        }
        let isNewBundle = childItems.isEmpty
        guard configurations != initialConfigurations || isNewBundle else {
            return
        }
        onConfigure(configurations)
    }

    /// Invoked when the retry CTA is tapped.
    func retry() {
        loadProductsAndCreateItemViewModels()
    }
}

private extension ConfigurableBundleProductViewModel {
    func loadProductsAndCreateItemViewModels() {
        loadProductsErrorMessage = nil

        Task { @MainActor in
            do {
                // When there is a long list of bundle items, products are loaded in a paginated way.
                let products = try await loadProducts(from: product.bundledItems)
                createItemViewModels(products: products)
            } catch {
                DDLogError("⛔️ Error loading products for bundle product items in order form: \(error)")
                loadProductsErrorMessage = Localization.errorLoadingProducts
            }
        }
    }

    func createItemViewModels(products: [Product]) {
        bundleItemViewModels = product.bundledItems
            .compactMap { bundleItem -> ConfigurableBundleItemViewModel? in
                guard let product = products.first(where: { $0.productID == bundleItem.productID }) else {
                    return nil
                }
                let existingOrderItem = childItems.first(where: { $0.productID == bundleItem.productID })
                switch product.productType {
                    case .variable:
                        let allowedVariations = bundleItem.overridesVariations ? bundleItem.allowedVariations: []
                        let defaultAttributes = bundleItem.overridesDefaultVariationAttributes ? bundleItem.defaultVariationAttributes: []
                        return .init(bundleItem: bundleItem,
                                     product: product,
                                     variableProductSettings:
                                .init(allowedVariations: allowedVariations, defaultAttributes: defaultAttributes),
                                     existingParentOrderItem: orderItem,
                                     existingOrderItem: existingOrderItem)
                    default:
                        return .init(bundleItem: bundleItem,
                                     product: product,
                                     variableProductSettings: nil,
                                     existingParentOrderItem: orderItem,
                                     existingOrderItem: existingOrderItem)
                }
            }
        initialConfigurations = bundleItemViewModels.compactMap { $0.toConfiguration }
    }

    @MainActor
    func loadProducts(from bundleItems: [ProductBundleItem]) async throws -> [Product] {
        let bundledProductIDs = bundleItems.map { $0.productID }
        return try await loadProductsRecursively(siteID: product.siteID, productIDs: bundledProductIDs)
    }

    func loadProductsRecursively(siteID: Int64, productIDs: [Int64]) async throws -> [Product] {
        let pageNumber = Store.Default.firstPageNumber
        return try await loadProducts(siteID: siteID, productIDs: productIDs, pageNumber: pageNumber, products: [])
    }

    func loadProducts(siteID: Int64, productIDs: [Int64], pageNumber: Int, products: [Product]) async throws -> [Product] {
        do {
            let (loadedProducts, hasNextPage) = try await loadProducts(siteID: siteID, productIDs: productIDs, pageNumber: pageNumber)
            let products = products + loadedProducts
            guard hasNextPage == false else {
                return try await loadProducts(siteID: siteID, productIDs: productIDs, pageNumber: pageNumber + 1, products: products)
            }
            return products
        } catch {
            throw error
        }
    }

    @MainActor
    func loadProducts(siteID: Int64, productIDs: [Int64], pageNumber: Int) async throws -> (products: [Product], hasNextPage: Bool) {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.retrieveProducts(siteID: product.siteID,
                                                           productIDs: productIDs,
                                                           pageNumber: pageNumber) { result in
                continuation.resume(with: result)
            })
        }
    }
}

private extension ConfigurableBundleProductViewModel {
    func validateBundleSize() -> Bool {
        let bundleItemCount = bundleItemViewModels.map { !$0.isOptional || $0.isOptionalAndSelected ? $0.quantity: 0 }.sum()
        if let bundleMinSize = product.bundleMinSize, bundleItemCount < bundleMinSize {
            validationErrorMessage = createBundleSizeValidationErrorMessage()
            return false
        }
        if let bundleMaxSize = product.bundleMaxSize, bundleItemCount > bundleMaxSize {
            validationErrorMessage = createBundleSizeValidationErrorMessage()
            return false
        }
        return true
    }

    func createBundleSizeValidationErrorMessage() -> String? {
        let itemSingular = Localization.ValidationError.itemSingular
        let itemPlural = Localization.ValidationError.itemPlural
        if let bundleMinSize = product.bundleMinSize, let bundleMaxSize = product.bundleMaxSize {
            return bundleMinSize == bundleMaxSize ?
            String.localizedStringWithFormat(Localization.ValidationError.bundleSizeNotExactFormat,
                                             "\(bundleMinSize)", String.pluralize(bundleMinSize, singular: itemSingular, plural: itemPlural)):
            String.localizedStringWithFormat(Localization.ValidationError.bundleSizeNotWithinRangeFormat,
                                             "\(bundleMinSize)", "\(bundleMaxSize)")
        } else if let bundleMinSize = product.bundleMinSize {
            return String.localizedStringWithFormat(Localization.ValidationError.bundleSizeLessThanMinimumFormat,
                                                    "\(bundleMinSize)", String.pluralize(bundleMinSize, singular: itemSingular, plural: itemPlural))
        } else if let bundleMaxSize = product.bundleMaxSize {
            return String.localizedStringWithFormat(Localization.ValidationError.bundleSizeGreaterThanMaximumFormat,
                                                    "\(bundleMaxSize)", String.pluralize(bundleMaxSize, singular: itemSingular, plural: itemPlural))
        } else {
            return nil
        }
    }
}

private extension ConfigurableBundleProductViewModel {
    enum Localization {
        static let errorLoadingProducts = NSLocalizedString(
            "configureBundleProductError.cannotLoadProducts",
            value: "Cannot load the bundled products. Please try again.",
            comment: "Error message when the products cannot be loaded in the bundle product configuration form."
        )
        enum ValidationError {
            static let bundleSizeNotWithinRangeFormat = NSLocalizedString(
                "configureBundleProductValidationError.bundleSizeNotWithinRange",
                value: "Please choose %1$@-%2$@ items.",
                comment: "Error message when the product bundle size is not within a min/max range if both rules are specified." +
                "%1$@ is the minimum bundle size. %2$@ is the minimum bundle size."
            )
            static let bundleSizeNotExactFormat = NSLocalizedString(
                "configureBundleProductValidationError.bundleSizeNotExact",
                value: "Please choose %1$@ %2$@.",
                comment: "Error message when the product bundle size is not matching the exact size if both rules are specified and " +
                "the min/max are the same." +
                "%1$@ is the expected bundle size. %2$@ is either 'item' or 'items' based on whether the bundle size is 1 or more."
            )
            static let bundleSizeLessThanMinimumFormat = NSLocalizedString(
                "configureBundleProductValidationError.bundleSizeLessThanMinimum",
                value: "Please choose at least %1$@ %2$@.",
                comment: "Error message when the product bundle size is less than the minimum if a minimum rule is specified." +
                "%1$@ is the minimum bundle size. %2$@ is either 'item' or 'items' based on whether the bundle size is 1 or more."
            )
            static let bundleSizeGreaterThanMaximumFormat = NSLocalizedString(
                "configureBundleProductValidationError.bundleSizeGreaterThanMaximum",
                value: "Please choose up to %1$@ %2$@.",
                comment: "Error message when the product bundle size is greater than the maximum if a maximum rule is specified." +
                "%1$@ is the maximum bundle size. %2$@ is either 'item' or 'items' based on whether the bundle size is 1 or more."
            )
            static let itemSingular = NSLocalizedString(
                "configureBundleProductValidationError.itemSingular",
                value: "item",
                comment: "Used in configureBundleProductValidationError strings for the singular form of item."
            )
            static let itemPlural = NSLocalizedString(
                "configureBundleProductValidationError.itemPlural",
                value: "items",
                comment: "Used in configureBundleProductValidationError strings for the plural form of item."
            )
        }
    }
}
