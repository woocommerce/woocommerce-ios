import Foundation

import Yosemite
import Combine
import WooFoundation

/// View model for `ConfigurableBundleProductView`.
final class ConfigurableBundleProductViewModel: ObservableObject, Identifiable {
    @Published private(set) var bundleItemViewModels: [ConfigurableBundleItemViewModel] = [] {
        didSet {
            observeBundleItemsForValidation()
        }
    }

    // MARK: - Validation

    @Published private var bundleItemErrorMessagesByItemID: [Int64: String?] = [:]
    @Published private var bundleItemQuantitiesByItemID: [Int64: Decimal] = [:]

    @Published private(set) var isConfigureEnabled: Bool = false

    typealias ValidationError = ConfigurableBundleNoticeView.ValidationError
    @Published private(set) var showsValidationNotice: Bool = false
    @Published private(set) var validationState: Result<Void, ValidationError> = .success(())
    @Published private var validationErrorMessage: String?
    @Published private(set) var loadProductsErrorMessage: String?

    /// View models for placeholder rows.
    let placeholderItemViewModels: [ConfigurableBundleItemViewModel]

    /// Closure invoked when the configure CTA is tapped to submit the configuration.
    /// If there are no changes to the configuration, the closure is not invoked.
    let onConfigure: (_ configurations: [BundledProductConfiguration]) -> Void

    /// Used to check if there are any outstanding changes to the configuration when submitting the form.
    /// This is set when the `bundleItemViewModels` are set.
    private var initialConfigurations: [BundledProductConfiguration] = []

    private var bundleItemSubscriptions = [AnyCancellable]()

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
        observeForValidation()
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

// MARK: - Validation

private extension ConfigurableBundleProductViewModel {
    func observeForValidation() {
        observeBundleItemQuantitiesForValidationErrorMessage()
        observeBundleItemsForValidation()
        observeBundleAndItemErrorMessagesForValidationState()
        observeValidationStateForNoticeVisibility()
        observeValidationStateForConfigureEnabledState()
    }

    func observeBundleItemQuantitiesForValidationErrorMessage() {
        $bundleItemQuantitiesByItemID
            .map { $0.values.sum() }
            .map { [weak self] in
                self?.validateBundleSize(bundleItemCount: $0)
            }
            .assign(to: &$validationErrorMessage)
    }

    func observeBundleAndItemErrorMessagesForValidationState() {
        let itemErrorMessages = $bundleItemErrorMessagesByItemID
            .map { $0.values }
        Publishers.CombineLatest(itemErrorMessages, $validationErrorMessage)
            .map { itemErrorMessages, validationErrorMessage in
                let errorMessages = ([validationErrorMessage] + itemErrorMessages).compactMap { $0 }

                guard let firstErrorMessage = errorMessages.first else {
                    return .success(())
                }
                return .failure(.init(message: firstErrorMessage))
            }
            .assign(to: &$validationState)
    }

    func observeValidationStateForNoticeVisibility() {
        $validationState
            .removeDuplicates(by: { lhs, rhs in
                switch (lhs, rhs) {
                    case (.failure(let lhsError), .failure(let rhsError)):
                        return lhsError == rhsError
                    case (.success, .success):
                        return true
                    default:
                        return false
                }
            })
            .withPrevious()
            .map { previous, current in
                guard current.isSuccess else {
                    return true
                }
                return previous?.isFailure == true
            }
            .assign(to: &$showsValidationNotice)
    }

    func observeValidationStateForConfigureEnabledState() {
        $validationState
            .map { $0.isSuccess }
            .assign(to: &$isConfigureEnabled)
    }

    func observeBundleItemsForValidation() {
        bundleItemErrorMessagesByItemID.removeAll()
        bundleItemQuantitiesByItemID.removeAll()
        bundleItemViewModels.forEach { itemViewModel in
            itemViewModel.$errorMessage.sink { [weak self] errorMessage in
                self?.bundleItemErrorMessagesByItemID[itemViewModel.bundledItemID] = errorMessage
            }
            .store(in: &bundleItemSubscriptions)

            itemViewModel.$quantityInBundle.sink { [weak self] quantity in
                self?.bundleItemQuantitiesByItemID[itemViewModel.bundledItemID] = quantity
            }
            .store(in: &bundleItemSubscriptions)
        }
    }
}

private extension ConfigurableBundleProductViewModel {
    /// Validates bundle size based on the given total number of items, and returns an error message if the size is invalid.
    /// - Parameter bundleItemCount: Total number of items in the bundle, excluding non-selected items.
    /// - Returns: An error message if the bundle size is invalid. Otherwise, `nil` is returned.
    func validateBundleSize(bundleItemCount: Decimal) -> String? {
        if let bundleMinSize = product.bundleMinSize, bundleItemCount < bundleMinSize {
            return createBundleSizeValidationErrorMessage()
        }
        if let bundleMaxSize = product.bundleMaxSize, bundleItemCount > bundleMaxSize {
            return createBundleSizeValidationErrorMessage()
        }
        return nil
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
