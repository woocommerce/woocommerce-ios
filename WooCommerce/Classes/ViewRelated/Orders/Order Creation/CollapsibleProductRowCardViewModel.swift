import Experiments
import SwiftUI
import WooFoundation
import Yosemite

/// View model for `CollapsibleProductCard`.
struct CollapsibleProductCardViewModel: Identifiable {
    var id: Int64 {
        productRow.id
    }

    /// The main/parent product row.
    let productRow: CollapsibleProductRowCardViewModel

    /// Child product rows, if the product is the parent of child order items
    let childProductRows: [CollapsibleProductRowCardViewModel]

    init(productRow: CollapsibleProductRowCardViewModel,
         childProductRows: [CollapsibleProductRowCardViewModel]) {
        self.productRow = productRow
        self.childProductRows = childProductRows
    }
}

/// View model for `CollapsibleProductRowCard`.
struct CollapsibleProductRowCardViewModel: Identifiable {
    /// Unique ID for view model
    let id: Int64

    /// ID for product or variation in row
    let productOrVariationID: Int64

    /// Whether a product in an order item has a parent order item
    let hasParentProduct: Bool

    /// Whether the product row is read-only. Defaults to `false`.
    ///
    /// Used to remove product editing controls for read-only order items (e.g. child items of a product bundle).
    let isReadOnly: Bool

    /// Whether a product in an order item is configurable
    let isConfigurable: Bool

    /// Closure to configure a product if it is configurable.
    let configure: (() -> Void)?

    /// The product image for the order item
    ///
    let imageURL: URL?

    /// The name of the order item
    ///
    let name: String

    /// Label showing the product SKU for an order item
    ///
    let skuLabel: String

    /// Product price (including discounts)
    ///
    let price: String?

    /// Product subtotal (price x quantity, not including discounts)
    ///
    let subtotal: String

    /// Product total (price x quantity, including discounts)
    ///
    let total: String

    /// Product discount
    ///
    let discount: Decimal?

    /// Label showing product details for an order item.
    /// Can include product type (if the row is configurable), variation attributes (if available), and stock status.
    ///
    let productDetailsLabel: String

    let stepperViewModel: ProductStepperViewModel
    let priceSummaryViewModel: CollapsibleProductCardPriceSummaryViewModel

    private let currencyFormatter: CurrencyFormatter
    private let analytics: Analytics

    init(id: Int64,
         productOrVariationID: Int64,
         hasParentProduct: Bool = false,
         isReadOnly: Bool = false,
         isConfigurable: Bool = false,
         imageURL: URL?,
         name: String,
         sku: String?,
         price: String?,
         subtotal: String,
         total: String,
         pricedIndividually: Bool = true,
         discount: Decimal? = nil,
         productTypeDescription: String,
         attributes: [VariationAttributeViewModel],
         stockStatus: ProductStockStatus,
         stockQuantity: Decimal?,
         manageStock: Bool,
         stepperViewModel: ProductStepperViewModel,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         analytics: Analytics = ServiceLocator.analytics,
         configure: (() -> Void)? = nil) {
        self.id = id
        self.productOrVariationID = productOrVariationID
        self.hasParentProduct = hasParentProduct
        self.isReadOnly = isReadOnly
        self.isConfigurable = configure != nil ? isConfigurable : false
        self.configure = configure
        self.imageURL = imageURL
        self.name = name
        self.price = price
        self.subtotal = subtotal
        self.total = total
        self.discount = discount
        skuLabel = CollapsibleProductRowCardViewModel.createSKULabel(sku: sku)
        productDetailsLabel = CollapsibleProductRowCardViewModel.createProductDetailsLabel(isConfigurable: isConfigurable,
                                                                                           productTypeDescription: productTypeDescription,
                                                                                           attributes: attributes,
                                                                                           stockStatus: stockStatus,
                                                                                           stockQuantity: stockQuantity,
                                                                                           manageStock: manageStock)
        self.stepperViewModel = stepperViewModel
        let priceBeforeDiscount = CollapsibleProductRowCardViewModel.calculatePriceBeforeDiscount(subtotal: subtotal,
                                                                                                  quantity: stepperViewModel.quantity,
                                                                                                  currencyFormatter: currencyFormatter) ?? price
        self.priceSummaryViewModel = .init(pricedIndividually: pricedIndividually,
                                           quantity: stepperViewModel.quantity,
                                           priceBeforeDiscount: priceBeforeDiscount,
                                           subtotal: subtotal)
        self.currencyFormatter = currencyFormatter
        self.analytics = analytics

        observeProductQuantityFromStepperViewModel()
    }

    /// Initialize `CollapsibleProductRowCardViewModel` with a `Product` and `OrderItem`
    init(orderItem: OrderItem,
         product: Product,
         isReadOnly: Bool,
         pricedIndividually: Bool,
         discount: Decimal?,
         quantityUpdatedCallback: @escaping (Decimal) -> Void,
         removeProductIntent: (() -> Void)? = nil,
         configure: (() -> Void)? = nil,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         analytics: Analytics = ServiceLocator.analytics) {
        let stepperViewModel = ProductStepperViewModel(quantity: orderItem.quantity,
                                                       name: orderItem.name,
                                                       quantityUpdatedCallback: quantityUpdatedCallback,
                                                       removeProductIntent: removeProductIntent)

        self.init(id: orderItem.itemID,
                  productOrVariationID: product.productID,
                  hasParentProduct: orderItem.parent != nil,
                  isReadOnly: isReadOnly,
                  isConfigurable: product.productType == .bundle && product.bundledItems.isNotEmpty,
                  imageURL: product.imageURL,
                  name: orderItem.name,
                  sku: orderItem.sku,
                  price: orderItem.price.description,
                  subtotal: orderItem.subtotal,
                  total: orderItem.total,
                  pricedIndividually: pricedIndividually,
                  discount: discount,
                  productTypeDescription: product.productType.description,
                  attributes: [],
                  stockStatus: product.productStockStatus,
                  stockQuantity: product.stockQuantity,
                  manageStock: product.manageStock,
                  stepperViewModel: stepperViewModel,
                  currencyFormatter: currencyFormatter,
                  analytics: analytics,
                  configure: configure)
    }

    /// Initialize `CollapsibleProductRowCardViewModel` with a `ProductVariation` and `OrderItem`
    init(orderItem: OrderItem,
         variation: ProductVariation,
         variableProduct: Product?,
         isReadOnly: Bool,
         pricedIndividually: Bool,
         discount: Decimal?,
         quantityUpdatedCallback: @escaping (Decimal) -> Void,
         removeProductIntent: (() -> Void)? = nil,
         configure: (() -> Void)? = nil,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         analytics: Analytics = ServiceLocator.analytics) {
        let attributes = ProductVariationFormatter().generateAttributes(for: variation, from: variableProduct?.attributes ?? [])
        let stepperViewModel = ProductStepperViewModel(quantity: orderItem.quantity,
                                                       name: orderItem.name,
                                                       quantityUpdatedCallback: quantityUpdatedCallback,
                                                       removeProductIntent: removeProductIntent)

        self.init(id: orderItem.itemID,
                  productOrVariationID: variation.productVariationID,
                  hasParentProduct: orderItem.parent != nil,
                  isReadOnly: isReadOnly,
                  isConfigurable: false,
                  imageURL: variation.imageURL,
                  name: orderItem.name,
                  sku: orderItem.sku,
                  price: orderItem.price.description,
                  subtotal: orderItem.subtotal,
                  total: orderItem.total,
                  pricedIndividually: pricedIndividually,
                  discount: discount,
                  productTypeDescription: ProductType.variable.description,
                  attributes: attributes,
                  stockStatus: variation.stockStatus,
                  stockQuantity: variation.stockQuantity,
                  manageStock: variation.manageStock,
                  stepperViewModel: stepperViewModel,
                  currencyFormatter: currencyFormatter,
                  analytics: analytics,
                  configure: configure)
    }

    func trackAddDiscountTapped() {
        analytics.track(event: .Orders.productDiscountAddButtonTapped())
    }

    func trackEditDiscountTapped() {
        analytics.track(event: .Orders.productDiscountEditButtonTapped())
    }
}

extension CollapsibleProductRowCardViewModel {
    /// Formatted total price label including discounts, if any.
    /// e.g: If price before discounts is $5, quantity is 10, and discount is $1, outputs "$49.00"
    ///
    var totalPriceAfterDiscountLabel: String? {
        currencyFormatter.formatAmount(total)
    }

    /// Formatted discount label for an individual product
    ///
    var discountLabel: String? {
        guard let discount else {
            return nil
        }
        return currencyFormatter.formatAmount(discount)
    }

    var hasDiscount: Bool {
        discount != nil
    }
}

private extension CollapsibleProductRowCardViewModel {
    /// Creates the label showing product details for an order item.
    /// Can include product type (if the row is configurable), variation attributes (if available), and stock status.
    ///
    static func createProductDetailsLabel(isConfigurable: Bool,
                                          productTypeDescription: String,
                                          attributes: [VariationAttributeViewModel] = [],
                                          stockStatus: ProductStockStatus,
                                          stockQuantity: Decimal?,
                                          manageStock: Bool) -> String {
        let productTypeLabel: String? = isConfigurable ? productTypeDescription : nil
        let attributesLabel: String? = attributes.isNotEmpty ? attributes.map { $0.nameOrValue }.joined(separator: ", ") : nil
        let stockLabel = createStockText(stockStatus: stockStatus, stockQuantity: stockQuantity, manageStock: manageStock)

        return [productTypeLabel, attributesLabel, stockLabel]
            .compactMap({ $0 })
            .filter { $0.isNotEmpty }
            .joined(separator: " • ")
    }

    /// Creates the stock text based on a product's stock status/quantity.
    ///
    static func createStockText(stockStatus: ProductStockStatus, stockQuantity: Decimal?, manageStock: Bool) -> String {
        switch (stockStatus, stockQuantity, manageStock) {
        case (.inStock, .some(let stockQuantity), true):
            let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
            return String.localizedStringWithFormat(Localization.stockFormat, localizedStockQuantity)
        default:
            return stockStatus.description
        }
    }

    /// Creates the label showing the product SKU for an order item.
    ///
    static func createSKULabel(sku: String?) -> String {
        guard let sku, sku.isNotEmpty else {
            return ""
        }
        return String.localizedStringWithFormat(Localization.skuFormat, sku)
    }

    /// Calculates the price before discount.
    ///
    /// - Parameters:
    ///   - subtotal: Total price for the item x quantity, without discount
    ///   - quantity: Item quantity
    ///   - discount: Total discount (all items)
    ///   - currencyFormatter: Currency formatter
    static func calculatePriceBeforeDiscount(subtotal: String, quantity: Decimal, currencyFormatter: CurrencyFormatter) -> String? {
        guard let decimalSubtotal = currencyFormatter.convertToDecimal(subtotal) else {
            return nil
        }
        return decimalSubtotal.dividing(by: quantity as NSDecimalNumber).description
    }
}

private extension CollapsibleProductRowCardViewModel {
    func observeProductQuantityFromStepperViewModel() {
        stepperViewModel.$quantity
            .assign(to: &priceSummaryViewModel.$quantity)
    }
}

private extension CollapsibleProductRowCardViewModel {
    enum Localization {
        static let stockFormat = NSLocalizedString("CollapsibleProductRowCardViewModel.stockFormat",
                                                   value: "%1$@ in stock",
                                                   comment: "Label about product's inventory stock status shown during order creation")
        static let skuFormat = NSLocalizedString("CollapsibleProductRowCardViewModel.skuFormat",
                                                 value: "SKU: %1$@",
                                                 comment: "SKU label for a product in an order. The variable shows the SKU of the product.")
    }
}
