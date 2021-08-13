import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for ShippingLabelsCustomsFormList
///
final class ShippingLabelCustomsFormListViewModel: ObservableObject {
    /// Whether multiple packages are found.
    ///
    lazy var multiplePackagesDetected: Bool = {
        customsForms.count > 1
    }()

    /// References of input view models.
    ///
    private(set) var inputViewModels: [ShippingLabelCustomsFormInputViewModel]

    /// Input customs forms of the shipping label if added initially.
    ///
    @Published var customsForms: [ShippingLabelCustomsForm]

    /// Associated order of the shipping label.
    ///
    private let order: Order

    /// Stores to sync data of products and variations.
    ///
    private let stores: StoresManager

    /// Storage to fetch products and variations.
    ///
    private let storageManager: StorageManagerType

    /// Persisted countries to send to item details form.
    ///
    private let allCountries: [Country]

    /// Reusing Package Details results controllers since we're interested in the same models.
    ///
    private var resultsControllers: ShippingLabelPackageDetailsResultsControllers?

    /// Products contained inside the Order and fetched from Core Data
    ///
    @Published private var products: [Product] = []

    /// ProductVariations contained inside the Order and fetched from Core Data
    ///
    @Published private var productVariations: [ProductVariation] = []

    init(order: Order,
         customsForms: [ShippingLabelCustomsForm],
         countries: [Country],
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.customsForms = customsForms
        self.stores = stores
        self.storageManager = storageManager
        self.allCountries = countries
        self.inputViewModels = customsForms.map { .init(customsForm: $0, countries: countries, currency: order.currency) }

        configureResultsControllers()
        updateItemDetails()
    }
}

// MARK: - Fetching and updating item details.
//
private extension ShippingLabelCustomsFormListViewModel {
    /// Update item details for current customs forms
    /// with every change in products and product variations.
    ///
    func updateItemDetails() {
        $products.combineLatest($productVariations) { [weak self] (products, variations) -> [ShippingLabelCustomsForm] in
            self?.updateCustomsForms(products: products, productVariations: variations) ?? []
        }
        .handleEvents(receiveOutput: { [weak self] customsForms in
            guard let self = self else { return }
            self.inputViewModels = customsForms.map { .init(customsForm: $0, countries: self.allCountries, currency: self.order.currency) }
        })
        .assign(to: &$customsForms)
    }

    /// Configure result controllers for products and product variations.
    ///
    func configureResultsControllers() {
        resultsControllers = ShippingLabelPackageDetailsResultsControllers(siteID: order.siteID,
                                                                           orderItems: order.items,
                                                                           storageManager: storageManager,
           onProductReload: { [weak self] (products) in
            self?.products = products
        }, onProductVariationsReload: { [weak self] (productVariations) in
            self?.productVariations = productVariations
        })

        products = resultsControllers?.products ?? []
        productVariations = resultsControllers?.productVariations ?? []
    }

    /// Return copy of customs forms with updated item details based on fetched products and variations.
    ///
    func updateCustomsForms(products: [Product], productVariations: [ProductVariation]) -> [ShippingLabelCustomsForm] {
        var updatedForms: [ShippingLabelCustomsForm] = []

        for form in customsForms {
            let updatedItems = form.items.map { item -> ShippingLabelCustomsForm.Item in
                // Find the matching order item
                guard let orderItem = order.items.first(where: { $0.variationID == item.productID || $0.productID == item.productID }) else {
                    return item
                }

                let weight: Double = {
                    if orderItem.variationID > 0,
                       let productVariation = productVariations.first(where: { $0.productVariationID == orderItem.variationID }) {
                        return Double(productVariation.weight ?? "") ?? 0
                    } else if let product = products.first(where: { $0.productID == orderItem.productID }) {
                        return Double(product.weight ?? "0") ?? 0
                    }

                    return 0
                }()

                return .init(description: orderItem.name,
                             quantity: orderItem.quantity.intValue, // TODO: is this safe?
                             value: orderItem.price.doubleValue,
                             weight: weight,
                             hsTariffNumber: "",
                             originCountry: "",
                             productID: item.productID)
            }

            // Append new form with updated items
            updatedForms.append(.init(packageID: form.packageID,
                                      packageName: form.packageName,
                                      contentsType: form.contentsType,
                                      contentExplanation: form.contentExplanation,
                                      restrictionType: form.restrictionType,
                                      restrictionComments: form.restrictionComments,
                                      nonDeliveryOption: form.nonDeliveryOption,
                                      itn: form.itn,
                                      items: updatedItems))
        }
        return updatedForms
    }
}
