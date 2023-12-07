import Experiments
import Foundation
import Yosemite
import WooFoundation
import Combine

/// View model for product rows or cards, e.g. `ProductRow` or `CollapsibleProductCard`.
///
final class ProductRowViewModel: ObservableObject, Identifiable {
    private let currencyFormatter: CurrencyFormatter

    let stepperViewModel: ProductStepperViewModel

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    ///
    let canChangeQuantity: Bool

    /// Whether the product row is read-only. Defaults to `false`.
    ///
    /// Used to remove product editing controls for read-only order items (e.g. child items of a product bundle).
    private(set) var isReadOnly: Bool = false

    /// Unique ID for the view model.
    ///
    let id: Int64

    // MARK: Product properties

    /// ID for the `Product` or `ProductVariation`
    ///
    let productOrVariationID: Int64

    /// The first available product image
    ///
    let imageURL: URL?

    /// Product name
    ///
    let name: String

    /// Whether a product in an order item has a parent order item
    let hasParentProduct: Bool

    /// Child product rows, if the product is the parent of child order items
    @Published private(set) var childProductRows: [ProductRowViewModel]

    /// Whether a product in an order item is configurable
    ///
    let isConfigurable: Bool

    /// Product SKU
    ///
    private let sku: String?

    /// Product price
    ///
    private(set) var price: String?

    /// Whether the product is priced individually. Defaults to `true`.
    ///
    /// Used to control how the price is displayed, e.g. when a product is part of a bundle.
    ///
    let pricedIndividually: Bool

    /// Product stock status
    ///
    private let stockStatus: ProductStockStatus

    /// Product stock quantity
    ///
    private let stockQuantity: Decimal?

    /// Whether the product's stock quantity is managed
    ///
    private let manageStock: Bool

    /// Display mode for a product variation.
    /// Determines which details to display in the product details label.
    ///
    private let variationDisplayMode: VariationDisplayMode?

    /// Stock or variation attributes label.
    /// Provides stock label for non-variations; uses variation display mode to determine the label for variations.
    ///
    private var stockOrAttributesLabel: String {
        switch variationDisplayMode {
        case .attributes(let attributes):
            return createAttributesText(from: attributes)
        default:
            return createStockText()
        }
    }

    /// Provides a stock quantity label when applicable
    ///
    var stockQuantityLabel: String {
        createStockQuantityText()
    }

    /// Formatted price label for an individual product
    ///
    var priceLabel: String? {
        guard let price = price else {
            return nil
        }
        return currencyFormatter.formatAmount(price)
    }

    /// Formatted discount label for an individual product
    ///
    var discountLabel: String? {
        guard let discount = discount else {
            return nil
        }
        return currencyFormatter.formatAmount(discount)
    }

    /// Formatted price label from multiplying product's price and quantity.
    ///
    var priceBeforeDiscountsLabel: String? {
        guard let price = price else {
            return nil
        }
        let productSubtotal = quantity * (currencyFormatter.convertToDecimal(price)?.decimalValue ?? Decimal.zero)
        return currencyFormatter.formatAmount(productSubtotal)
    }

    /// Formatted price label based on a product's price and quantity. Accounting for discounts, if any.
    /// e.g: If price is $5 and discount is $1, outputs "$5.00 - $1.00"
    ///
    var priceAndDiscountsLabel: String? {
        guard let price = price else {
            return nil
        }
        let productSubtotal = quantity * (currencyFormatter.convertToDecimal(price)?.decimalValue ?? Decimal.zero)
        let priceLabelComponent = currencyFormatter.formatAmount(productSubtotal)

        guard let priceLabelComponent = currencyFormatter.formatAmount(productSubtotal),
              let discount = discount,
              let discountLabelComponent = currencyFormatter.formatAmount(discount) else {
            return priceLabelComponent
        }

        return priceLabelComponent + " - " + discountLabelComponent
    }

    /// Formatted price label based on a product's price. Accounting for discounts, if any.
    /// e.g: If price is $5 and discount is $1, outputs "$4.00"
    ///
    var priceAfterDiscountLabel: String? {
        guard let price = price else {
            return nil
        }
        guard let priceDecimal = currencyFormatter.convertToDecimal(price) else {
            return nil
        }
        let priceAfterDiscount = priceDecimal.subtracting((discount ?? Decimal.zero) as NSDecimalNumber)

        return currencyFormatter.formatAmount(priceAfterDiscount) ?? ""
    }

    /// Formatted price label based on a product's price and quantity. Accounting for discounts, if any.
    /// e.g: If price is $5, quantity is 10, and discount is $1, outputs "$49.00"
    ///
    var totalPriceAfterDiscountLabel: String? {
        guard let price = price,
              let priceDecimal = currencyFormatter.convertToDecimal(price) else {
            return nil
        }
        let subtotalDecimal = priceDecimal.multiplying(by: quantity as NSDecimalNumber)
        let totalPriceAfterDiscount = subtotalDecimal.subtracting((discount ?? Decimal.zero) as NSDecimalNumber)

        return currencyFormatter.formatAmount(totalPriceAfterDiscount)

    }

    /// Formatted price label based on a product's price and quantity.
    /// Reads as '8 x $10.00'
    ///
    var priceQuantityLine: String {
        let quantity = quantity.formatted()
        let price = priceLabel ?? "-"
        return String.localizedStringWithFormat(Localization.priceQuantityLine, quantity, price)
    }

    private(set) var discount: Decimal?

    var hasDiscount: Bool {
        discount != nil
    }

    /// Whether product discounts are disallowed,
    /// defaults to `false`
    ///
    var shouldDisallowDiscounts: Bool = false

    /// Variations label for a variable product.
    ///
    private var variationsLabel: String? {
        guard numberOfVariations > 0 else {
            return nil
        }
        let format = String.pluralize(numberOfVariations, singular: Localization.singleVariation, plural: Localization.pluralVariations)
        return String.localizedStringWithFormat(format, numberOfVariations)
    }

    /// Label showing product details. Can include stock status or attributes, price, and variations (if any).
    ///
    var productDetailsLabel: String {
        [stockOrAttributesLabel, priceAndDiscountsLabel, variationsLabel]
            .compactMap({ $0 })
            .joined(separator: " • ")
    }

    /// Label showing secondary product details. Can include product type (if the row is configurable), and SKU (if available).
    ///
    var secondaryProductDetailsLabel: String {
        [productTypeLabel, skuLabel]
            .compactMap({ $0 })
            .filter { $0.isNotEmpty }
            .joined(separator: " • ")
    }

    /// Label showing product details for a product in an order.
    /// Can include product type (if the row is configurable), variation attributes (if available), and stock status.
    ///
    var orderProductDetailsLabel: String {
        let attributesLabel: String? = {
            guard case let .attributes(attributes) = variationDisplayMode else {
                return nil
            }
            return createAttributesText(from: attributes)
        }()
        let stockLabel = createStockText()
        return [productTypeLabel, attributesLabel, stockLabel]
            .compactMap({ $0 })
            .filter { $0.isNotEmpty }
            .joined(separator: " • ")
    }

    private let productTypeLabel: String?

    /// Label showing product SKU
    ///
    lazy var skuLabel: String = {
        guard let sku = sku, sku.isNotEmpty else {
            return ""
        }
        return String.localizedStringWithFormat(Localization.skuFormat, sku)
    }()

    /// Custom accessibility label for product.
    ///
    var productAccessibilityLabel: String {
        [name, stockOrAttributesLabel, priceAndDiscountsLabel, variationsLabel, skuLabel]
            .compactMap({ $0 })
            .joined(separator: ". ")
    }

    /// Quantity of product in the order. The source of truth is from the the quantity stepper view model `stepperViewModel`.
    ///
    @Published private(set) var quantity: Decimal

    /// Closure to run when the quantity is decremented below the minimum quantity.
    ///
    let removeProductIntent: (() -> Void)?

    /// Closure to configure a product if it is configurable.
    let configure: (() -> Void)?

    /// Number of variations in a variable product
    ///
    let numberOfVariations: Int

    /// Whether this row is currently selected
    ///
    let selectedState: ProductRow.SelectedState

    /// Analytics
    ///
    let analytics: Analytics

    init(id: Int64? = nil,
         productOrVariationID: Int64,
         name: String,
         sku: String?,
         productTypeLabel: String? = nil,
         price: String?,
         discount: Decimal? = nil,
         stockStatusKey: String,
         stockQuantity: Decimal?,
         manageStock: Bool,
         quantity: Decimal = 1,
         minimumQuantity: Decimal = 1,
         maximumQuantity: Decimal? = nil,
         canChangeQuantity: Bool,
         imageURL: URL?,
         numberOfVariations: Int = 0,
         variationDisplayMode: VariationDisplayMode? = nil,
         selectedState: ProductRow.SelectedState = .notSelected,
         hasParentProduct: Bool,
         pricedIndividually: Bool = true,
         childProductRows: [ProductRowViewModel] = [],
         isConfigurable: Bool,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         analytics: Analytics = ServiceLocator.analytics,
         quantityUpdatedCallback: @escaping ((Decimal) -> Void) = { _ in },
         removeProductIntent: (() -> Void)? = nil,
         configure: (() -> Void)? = nil) {
        self.id = id ?? Int64(UUID().uuidString.hashValue)
        self.selectedState = selectedState
        self.productOrVariationID = productOrVariationID
        self.name = name
        self.sku = sku
        self.productTypeLabel = productTypeLabel
        self.price = price
        self.discount = discount
        self.stockStatus = .init(rawValue: stockStatusKey)
        self.stockQuantity = stockQuantity
        self.manageStock = manageStock
        self.quantity = quantity
        self.stepperViewModel = ProductStepperViewModel(quantity: quantity,
                                                        name: name,
                                                        minimumQuantity: minimumQuantity,
                                                        maximumQuantity: maximumQuantity,
                                                        quantityUpdatedCallback: quantityUpdatedCallback,
                                                        removeProductIntent: removeProductIntent)
        self.canChangeQuantity = canChangeQuantity
        self.imageURL = imageURL
        self.hasParentProduct = hasParentProduct
        self.pricedIndividually = pricedIndividually
        self.childProductRows = childProductRows
        self.isConfigurable = isConfigurable
        self.currencyFormatter = currencyFormatter
        self.analytics = analytics
        self.numberOfVariations = numberOfVariations
        self.variationDisplayMode = variationDisplayMode
        self.removeProductIntent = removeProductIntent
        self.configure = configure

        observeQuantityFromStepperViewModel()
    }

    /// Initialize `ProductRowViewModel` with a `Product`
    ///
    convenience init(id: Int64? = nil,
                     product: Product,
                     discount: Decimal? = nil,
                     quantity: Decimal = 1,
                     canChangeQuantity: Bool,
                     selectedState: ProductRow.SelectedState = .notSelected,
                     hasParentProduct: Bool = false,
                     pricedIndividually: Bool = true,
                     childProductRows: [ProductRowViewModel] = [],
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     analytics: Analytics = ServiceLocator.analytics,
                     quantityUpdatedCallback: @escaping ((Decimal) -> Void) = { _ in },
                     removeProductIntent: @escaping (() -> Void) = {},
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     configure: (() -> Void)? = nil) {
        // Don't show any price for variable products; price will be shown for each product variation.
        let price: String?
        if product.productType == .variable {
            price = nil
        } else if !pricedIndividually {
            price = "0"
        } else {
            price = product.price
        }

        let productBundlesEnabled = featureFlagService.isFeatureFlagEnabled(.productBundles)

        // If product is a product bundle with insufficient bundle stock, use that as the product stock status.
        let stockStatusKey: String = {
            switch (productBundlesEnabled, product.productType, product.bundleStockStatus) {
            case (true, .bundle, .insufficientStock):
                return ProductStockStatus.insufficientStock.rawValue
            default:
                return product.stockStatusKey
            }
        }()

        // If product is a product bundle with a bundle stock quantity, use that as the product stock quantity.
        let stockQuantity: Decimal? = {
            switch (productBundlesEnabled, product.productType, product.bundleStockQuantity) {
            case (true, .bundle, .some(let bundleStockQuantity)):
                return Decimal(bundleStockQuantity)
            default:
                return product.stockQuantity
            }
        }()

        // If product is a product bundle with a bundle stock quantity, override product `manageStock` setting.
        let manageStock: Bool = {
            switch (productBundlesEnabled, product.productType, product.bundleStockQuantity) {
            case (true, .bundle, .some):
                return true
            default:
                return product.manageStock
            }
        }()

        let isConfigurable = featureFlagService.isFeatureFlagEnabled(.productBundlesInOrderForm)
        && product.productType == .bundle
        && product.bundledItems.isNotEmpty
        && configure != nil

        let productTypeLabel: String? = isConfigurable ? product.productType.description: nil

        if product.productType == .bundle {
            for child in childProductRows {
                child.isReadOnly = true // Can't edit child bundle items separate from bundle configuration
            }
        }

        self.init(id: id,
                  productOrVariationID: product.productID,
                  name: product.name,
                  sku: product.sku,
                  productTypeLabel: productTypeLabel,
                  price: price,
                  discount: discount,
                  stockStatusKey: stockStatusKey,
                  stockQuantity: stockQuantity,
                  manageStock: manageStock,
                  quantity: quantity,
                  canChangeQuantity: canChangeQuantity,
                  imageURL: product.imageURL,
                  numberOfVariations: product.variations.count,
                  selectedState: selectedState,
                  hasParentProduct: hasParentProduct,
                  pricedIndividually: pricedIndividually,
                  childProductRows: childProductRows,
                  isConfigurable: isConfigurable,
                  currencyFormatter: currencyFormatter,
                  analytics: analytics,
                  quantityUpdatedCallback: quantityUpdatedCallback,
                  removeProductIntent: removeProductIntent,
                  configure: configure)
    }

    /// Initialize `ProductRowViewModel` with a `ProductVariation`
    ///
    convenience init(id: Int64? = nil,
                     productVariation: ProductVariation,
                     discount: Decimal? = nil,
                     name: String,
                     quantity: Decimal = 1,
                     canChangeQuantity: Bool,
                     displayMode: VariationDisplayMode,
                     selectedState: ProductRow.SelectedState = .notSelected,
                     hasParentProduct: Bool = false,
                     pricedIndividually: Bool = true,
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     analytics: Analytics = ServiceLocator.analytics,
                     quantityUpdatedCallback: @escaping ((Decimal) -> Void) = { _ in },
                     removeProductIntent: @escaping (() -> Void) = {}) {
        let imageURL: URL?
        if let encodedImageURLString = productVariation.image?.src.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            imageURL = URL(string: encodedImageURLString)
        } else {
            imageURL = nil
        }

        self.init(id: id,
                  productOrVariationID: productVariation.productVariationID,
                  name: name,
                  sku: productVariation.sku,
                  price: pricedIndividually ? productVariation.price : "0",
                  discount: discount,
                  stockStatusKey: productVariation.stockStatus.rawValue,
                  stockQuantity: productVariation.stockQuantity,
                  manageStock: productVariation.manageStock,
                  quantity: quantity,
                  canChangeQuantity: canChangeQuantity,
                  imageURL: imageURL,
                  variationDisplayMode: displayMode,
                  selectedState: selectedState,
                  hasParentProduct: hasParentProduct,
                  pricedIndividually: pricedIndividually,
                  isConfigurable: false,
                  currencyFormatter: currencyFormatter,
                  analytics: analytics,
                  quantityUpdatedCallback: quantityUpdatedCallback,
                  removeProductIntent: removeProductIntent)
    }

    /// Determines which product variation details to display.
    ///
    enum VariationDisplayMode {
        /// Displays the variation's stock status
        case stock

        /// Displays the provided list of variation attributes
        case attributes([VariationAttributeViewModel])
    }

    /// Create the stock text based on a product's stock status/quantity.
    ///
    private func createStockText() -> String {
        switch stockStatus {
        case .inStock:
            if let stockQuantity = stockQuantity, manageStock {
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(Localization.stockFormat, localizedStockQuantity)
            } else {
                return stockStatus.description
            }
        default:
            return stockStatus.description
        }
    }

    /// Returns a text-based stock quantity if there's stock, or a fall-back when stock quantity doesn't apply
    ///
    private func createStockQuantityText() -> String {
        switch stockStatus {
        case .inStock:
            if let stockQuantity = stockQuantity, manageStock {
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(Localization.stockFormat, localizedStockQuantity)
            } else {
                return stockStatus.description
            }
        default:
            return stockStatus.description
        }
    }

    /// Create the attributes text based on the provided product variation attributes.
    ///
    private func createAttributesText(from attributes: [VariationAttributeViewModel]) -> String {
        return attributes.map { $0.nameOrValue }.joined(separator: ", ")
    }

    func trackAddDiscountTapped() {
        analytics.track(event: .Orders.productDiscountAddButtonTapped())
    }

    func trackEditDiscountTapped() {
        analytics.track(event: .Orders.productDiscountEditButtonTapped())
    }
}

private extension ProductRowViewModel {
    func observeQuantityFromStepperViewModel() {
        stepperViewModel.$quantity
            .assign(to: &$quantity)
    }
}

private extension ProductRowViewModel {
    enum Localization {
        static let priceQuantityLine = NSLocalizedString(
            "productRowViewModel.priceQuantityLine",
            value: "%@ × %@",
            comment: "Formatted price label based on a product's price and quantity. Reads as '8 x $10.00'. " +
            "Please take care to use the multiplication symbol ×, not a letter x, where appropriate.")
        static let stockFormat = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        static let singleVariation = NSLocalizedString("%ld variation",
                                                       comment: "Label for one product variation when showing details about a variable product")
        static let pluralVariations = NSLocalizedString("%ld variations",
                                                        comment: "Label for multiple product variations when showing details about a variable product")
    }
}
