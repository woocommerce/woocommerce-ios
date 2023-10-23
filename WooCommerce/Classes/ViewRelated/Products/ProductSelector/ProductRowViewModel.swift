import Foundation
import Yosemite
import WooFoundation

/// View model for `ProductRow`.
///
final class ProductRowViewModel: ObservableObject, Identifiable {
    private let currencyFormatter: CurrencyFormatter

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    ///
    let canChangeQuantity: Bool

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

    /// Product SKU
    ///
    private let sku: String?

    /// Product price
    ///
    private(set) var price: String?

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

    /// Formatted price label based on a product's price and quantity. Accounting for discounts, if any.
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

    /// Quantity of product in the order
    ///
    @Published private(set) var quantity: Decimal

    /// Minimum value of the product quantity
    ///
    private let minimumQuantity: Decimal = 1

    /// Whether the quantity can be decremented.
    ///
    var shouldDisableQuantityDecrementer: Bool {
        quantity < minimumQuantity
    }

    /// Closure to run when the quantity is changed.
    ///
    var quantityUpdatedCallback: (Decimal) -> Void

    /// Closure to run when the quantity is decremented below the minimum quantity.
    ///
    var removeProductIntent: () -> Void

    /// Number of variations in a variable product
    ///
    let numberOfVariations: Int

    /// Whether this row is currently selected
    ///
    let selectedState: ProductRow.SelectedState

    init(id: Int64? = nil,
         productOrVariationID: Int64,
         name: String,
         sku: String?,
         price: String?,
         discount: Decimal? = nil,
         stockStatusKey: String,
         stockQuantity: Decimal?,
         manageStock: Bool,
         quantity: Decimal = 1,
         canChangeQuantity: Bool,
         imageURL: URL?,
         numberOfVariations: Int = 0,
         variationDisplayMode: VariationDisplayMode? = nil,
         selectedState: ProductRow.SelectedState = .notSelected,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         quantityUpdatedCallback: @escaping ((Decimal) -> Void) = { _ in },
         removeProductIntent: @escaping (() -> Void) = {}) {
        self.id = id ?? Int64(UUID().uuidString.hashValue)
        self.selectedState = selectedState
        self.productOrVariationID = productOrVariationID
        self.name = name
        self.sku = sku
        self.price = price
        self.discount = discount
        self.stockStatus = .init(rawValue: stockStatusKey)
        self.stockQuantity = stockQuantity
        self.manageStock = manageStock
        self.quantity = quantity
        self.canChangeQuantity = canChangeQuantity
        self.imageURL = imageURL
        self.currencyFormatter = currencyFormatter
        self.numberOfVariations = numberOfVariations
        self.variationDisplayMode = variationDisplayMode
        self.quantityUpdatedCallback = quantityUpdatedCallback
        self.removeProductIntent = removeProductIntent
    }

    /// Initialize `ProductRowViewModel` with a `Product`
    ///
    convenience init(id: Int64? = nil,
                     product: Product,
                     discount: Decimal? = nil,
                     quantity: Decimal = 1,
                     canChangeQuantity: Bool,
                     selectedState: ProductRow.SelectedState = .notSelected,
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     quantityUpdatedCallback: @escaping ((Decimal) -> Void) = { _ in },
                     removeProductIntent: @escaping (() -> Void) = {},
                     productBundlesEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productBundles)) {
        // Don't show any price for variable products; price will be shown for each product variation.
        let price: String?
        if product.productType == .variable {
            price = nil
        } else {
            price = product.price
        }

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

        self.init(id: id,
                  productOrVariationID: product.productID,
                  name: product.name,
                  sku: product.sku,
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
                  currencyFormatter: currencyFormatter,
                  quantityUpdatedCallback: quantityUpdatedCallback,
                  removeProductIntent: removeProductIntent)
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
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
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
                  price: productVariation.price,
                  discount: discount,
                  stockStatusKey: productVariation.stockStatus.rawValue,
                  stockQuantity: productVariation.stockQuantity,
                  manageStock: productVariation.manageStock,
                  quantity: quantity,
                  canChangeQuantity: canChangeQuantity,
                  imageURL: imageURL,
                  variationDisplayMode: displayMode,
                  selectedState: selectedState,
                  currencyFormatter: currencyFormatter,
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

    /// Increment the product quantity.
    ///
    func incrementQuantity() {
        quantity += 1

        quantityUpdatedCallback(quantity)
    }

    /// Decrement the product quantity.
    ///
    func decrementQuantity() {
        guard quantity > minimumQuantity else {
            return removeProductIntent()
        }
        quantity -= 1

        quantityUpdatedCallback(quantity)
    }
}

private extension ProductRowViewModel {
    enum Localization {
        static let stockFormat = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        static let singleVariation = NSLocalizedString("%ld variation",
                                                       comment: "Label for one product variation when showing details about a variable product")
        static let pluralVariations = NSLocalizedString("%ld variations",
                                                        comment: "Label for multiple product variations when showing details about a variable product")
    }
}
