import Foundation
import Yosemite

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
    private let price: String?

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

    /// Label showing product details. Can include stock status or attributes, price, and variations (if any).
    ///
    var productDetailsLabel: String {
        let stockOrAttributesLabel = createStockOrAttributesText()
        let priceLabel = createPriceText()
        let variationsLabel = createVariationsText()

        return [stockOrAttributesLabel, priceLabel, variationsLabel]
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

    /// Quantity of product in the order
    ///
    @Published private(set) var quantity: Decimal

    /// Minimum value of the product quantity
    ///
    private let minimumQuantity: Decimal = 1

    /// Whether the quantity can be decremented.
    ///
    var shouldDisableQuantityDecrementer: Bool {
        quantity <= minimumQuantity
    }

    /// Number of variations in a variable product
    ///
    let numberOfVariations: Int

    init(id: Int64? = nil,
         productOrVariationID: Int64,
         name: String,
         sku: String?,
         price: String?,
         stockStatusKey: String,
         stockQuantity: Decimal?,
         manageStock: Bool,
         quantity: Decimal = 1,
         canChangeQuantity: Bool,
         imageURL: URL?,
         numberOfVariations: Int = 0,
         variationDisplayMode: VariationDisplayMode? = nil,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.id = id ?? Int64(UUID().uuidString.hashValue)
        self.productOrVariationID = productOrVariationID
        self.name = name
        self.sku = sku
        self.price = price
        self.stockStatus = .init(rawValue: stockStatusKey)
        self.stockQuantity = stockQuantity
        self.manageStock = manageStock
        self.quantity = quantity
        self.canChangeQuantity = canChangeQuantity
        self.imageURL = imageURL
        self.currencyFormatter = currencyFormatter
        self.numberOfVariations = numberOfVariations
        self.variationDisplayMode = variationDisplayMode
    }

    /// Initialize `ProductRowViewModel` with a `Product`
    ///
    convenience init(id: Int64? = nil,
                     product: Product,
                     quantity: Decimal = 1,
                     canChangeQuantity: Bool,
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        // Don't show any price for variable products; price will be shown for each product variation.
        let price: String?
        if product.productType == .variable {
            price = nil
        } else {
            price = product.price
        }

        self.init(id: id,
                  productOrVariationID: product.productID,
                  name: product.name,
                  sku: product.sku,
                  price: price,
                  stockStatusKey: product.stockStatusKey,
                  stockQuantity: product.stockQuantity,
                  manageStock: product.manageStock,
                  quantity: quantity,
                  canChangeQuantity: canChangeQuantity,
                  imageURL: product.imageURL,
                  numberOfVariations: product.variations.count,
                  currencyFormatter: currencyFormatter)
    }

    /// Initialize `ProductRowViewModel` with a `ProductVariation`
    ///
    convenience init(id: Int64? = nil,
                     productVariation: ProductVariation,
                     name: String,
                     quantity: Decimal = 1,
                     canChangeQuantity: Bool,
                     displayMode: VariationDisplayMode,
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
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
                  stockStatusKey: productVariation.stockStatus.rawValue,
                  stockQuantity: productVariation.stockQuantity,
                  manageStock: productVariation.manageStock,
                  quantity: quantity,
                  canChangeQuantity: canChangeQuantity,
                  imageURL: imageURL,
                  variationDisplayMode: displayMode,
                  currencyFormatter: currencyFormatter)
    }

    /// Determines which product variation details to display.
    ///
    enum VariationDisplayMode {
        /// Displays the variation's stock status
        case stock

        /// Displays the provided list of variation attributes
        case attributes([VariationAttributeViewModel])
    }

    /// Creates the stock or variation attributes text.
    /// Returns stock text for non-variations; uses variation display mode to determine the text for variations.
    ///
    private func createStockOrAttributesText() -> String {
        switch variationDisplayMode {
        case .attributes(let attributes):
            return createAttributesText(from: attributes)
        default:
            return createStockText()
        }
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

    /// Create the attributes text based on the provided product variation attributes.
    ///
    private func createAttributesText(from attributes: [VariationAttributeViewModel]) -> String {
        return attributes.map { $0.nameOrValue }.joined(separator: ", ")
    }

    /// Create the price text based on a product's price and quantity.
    ///
    private func createPriceText() -> String? {
        guard let price = price else {
            return nil
        }
        let productSubtotal = quantity * (currencyFormatter.convertToDecimal(from: price)?.decimalValue ?? Decimal.zero)
        return currencyFormatter.formatAmount(productSubtotal)
    }

    /// Create the variations text for a variable product.
    ///
    private func createVariationsText() -> String? {
        guard numberOfVariations > 0 else {
            return nil
        }
        let format = String.pluralize(numberOfVariations, singular: Localization.singleVariation, plural: Localization.pluralVariations)
        return String.localizedStringWithFormat(format, numberOfVariations)
    }

    /// Increment the product quantity.
    ///
    func incrementQuantity() {
        quantity += 1
    }

    /// Decrement the product quantity.
    ///
    func decrementQuantity() {
        guard quantity > minimumQuantity else {
            return
        }
        quantity -= 1
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
