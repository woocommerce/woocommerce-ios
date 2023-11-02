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

    /// Closure invoked when the configure CTA is tapped to submit the configuration.
    /// If there are no changes to the configuration, the closure is not invoked.
    let onConfigure: (_ configurations: [BundledProductConfiguration]) -> Void

    /// Used to check if there are any outstanding changes to the configuration when submitting the form.
    /// This is set when the `bundleItemViewModels` are set.
    private var initialConfigurations: [BundledProductConfiguration] = []

    private let product: Product
    private let childItems: [OrderItem]
    private let stores: StoresManager

    /// - Parameters:
    ///   - product: Bundle product in an order item.
    ///   - childItems: Pre-existing bundled order items.
    ///   - stores: For dispatching actions.
    ///   - onConfigure: Invoked when the configuration is confirmed.
    init(product: Product,
         childItems: [OrderItem],
         stores: StoresManager = ServiceLocator.stores,
         onConfigure: @escaping (_ configurations: [BundledProductConfiguration]) -> Void) {
        self.product = product
        self.childItems = childItems
        self.stores = stores
        self.onConfigure = onConfigure
        loadProductsAndCreateItemViewModels()
    }

    /// Validates the bundle configuration of all bundled items.
    /// - Returns: A boolean that indicates whether the configuration is valid.
    func validate() -> Bool {
        !bundleItemViewModels.map({ $0.validate() }).contains(false)
    }

    /// Completes the bundle configuration and triggers the configuration callback.
    func configure() {
        let configurations: [BundledProductConfiguration] = bundleItemViewModels.compactMap {
            $0.toConfiguration
        }
        guard configurations != initialConfigurations else {
            return
        }
        onConfigure(configurations)
    }
}

private extension ConfigurableBundleProductViewModel {
    func loadProductsAndCreateItemViewModels() {
        Task { @MainActor in
            do {
                // When there is a long list of bundle items, products are loaded in a paginated way.
                let products = try await loadProducts(from: product.bundledItems)
                createItemViewModels(products: products)
            } catch {
                // TODO: 10428 - handle error loading products for bundle items
                DDLogError("⛔️ Error loading products for bundle product items in order form:  \(error)")
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
                                     existingOrderItem: existingOrderItem)
                    default:
                        return .init(bundleItem: bundleItem, product: product, variableProductSettings: nil, existingOrderItem: existingOrderItem)
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
