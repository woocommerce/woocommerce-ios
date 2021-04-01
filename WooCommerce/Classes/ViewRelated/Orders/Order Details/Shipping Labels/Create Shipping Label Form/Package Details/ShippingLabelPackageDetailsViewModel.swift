import UIKit
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `ShippingLabelPackageDetails`.
///
final class ShippingLabelPackageDetailsViewModel: ObservableObject {

    private let order: Order
    private let orderItems: [OrderItem]
    private let currency: String
    private let currencyFormatter: CurrencyFormatter
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private var resultsControllers: ShippingLabelPackageDetailsResultsControllers?

    /// Products contained inside the Order and fetched from Core Data
    ///
    private var products: [Product] = []

    /// ProductVariations contained inside the Order and fetched from Core Data
    ///
    private var productVariations: [ProductVariation] = []

    /// The weight unit used in the Store
    ///
    let weightUnit: String?

    /// The items rows observed by the main view `ShippingLabelPackageDetails`
    ///
    @Published var itemsRows: [ItemToFulfillRow] = []

    init(order: Order,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService) {
        self.order = order
        self.orderItems = order.items
        self.currency = order.currency
        self.currencyFormatter = formatter
        self.stores = stores
        self.storageManager = storageManager
        weightUnit = shippingSettingsService.weightUnit
        instantiateResultsControllers()
        syncProducts()
        syncProductVariations()
    }

    private func instantiateResultsControllers() {
        resultsControllers = ShippingLabelPackageDetailsResultsControllers(siteID: order.siteID,
                                                                           orderItems: order.items,
           onProductReload: { [weak self] (products) in
            guard let self = self else { return }
            self.products = products
            self.itemsRows = self.generateItemsRows()
        }, onProductVariationsReload: { [weak self] (productVariations) in
            guard let self = self else { return }
            self.productVariations = productVariations
            self.itemsRows = self.generateItemsRows()
        })

        products = resultsControllers?.products ?? []
        productVariations = resultsControllers?.productVariations ?? []
        itemsRows = generateItemsRows()
    }

    /// Generate the items rows, creating an element in the array for every item (eg. if there are an item with quantity 3,
    /// we will generate 3 different items), and we will remove virtual products. 
    ///
    private func generateItemsRows() -> [ItemToFulfillRow] {
        var itemsToFulfill: [ItemToFulfillRow] = []
        for item in orderItems {
            let isVariation = item.variationID > 0
            var product: Product?
            var productVariation: ProductVariation?

            if isVariation {
                productVariation = productVariations.first { $0.productVariationID == item.variationID }
            }
            else {
                product = products.first { $0.productID == item.productID }
            }
            guard product?.virtual == false || productVariation?.virtual == false else {
                break
            }

            for _ in 0..<item.quantity.intValue {
                let attributes = item.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) }
                let weightUnitA: String = weightUnit ?? ""
                let subtitle = Localization.subtitle(weight: isVariation ? productVariation?.weight : product?.weight, attributes: attributes) + weightUnitA
                itemsToFulfill.append(ItemToFulfillRow(title: item.name, subtitle: subtitle))
            }
        }
        return itemsToFulfill
    }
}

/// API Requests
///
private extension ShippingLabelPackageDetailsViewModel {
    func syncProducts(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductAction.requestMissingProducts(for: order) { (error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing Products: \(error)")
                onCompletion?(error)
                return
            }

            onCompletion?(nil)
        }

        stores.dispatch(action)
    }

    func syncProductVariations(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductVariationAction.requestMissingVariations(for: order) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing missing variations in an Order: \(error)")
                onCompletion?(error)
                return
            }
            onCompletion?(nil)
        }
        stores.dispatch(action)
    }
}

private extension ShippingLabelPackageDetailsViewModel {
    enum Localization {
        static let subtitleFormat =
            NSLocalizedString("%1$@", comment: "In Shipping Labels Package Details,"
                                + " the pattern used to show the weight of a product. For example, “1lbs”.")
        static let subtitleWithAttributesFormat =
            NSLocalizedString("%1$@・%2$@", comment: "In Shipping Labels Package Details if the product has attributes,"
                                + " the pattern used to show the attributes and weight. For example, “purple, has logo・1lbs”."
                                + " The %1$@ is the list of attributes (e.g. from variation)."
                                + " The %2$@ is the weight.")
        static func subtitle(weight: String?, attributes: [VariationAttributeViewModel]) -> String {
            let attributesText = attributes.map { $0.nameOrValue }.joined(separator: ", ")
            if attributes.isEmpty {
                return String.localizedStringWithFormat(subtitleFormat, weight ?? "0")
            } else {
                return String.localizedStringWithFormat(subtitleWithAttributesFormat, attributesText, weight ?? "0")
            }
        }
    }
}
