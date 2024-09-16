import Experiments
import Foundation
import Yosemite
import WooFoundation
import Combine

/// View model for product rows or cards, e.g. `ProductRow` or `CollapsibleProductCard`.
///
final class ProductRowViewModel: ObservableObject, Identifiable {
    private let currencyFormatter: CurrencyFormatter

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

    /// Whether a product in an order item is configurable
    ///
    let isConfigurable: Bool

    /// Product SKU
    ///
    private let sku: String?

    /// Product price
    ///
    private(set) var price: String?

    // TODO: 11357 - Remove this property once `ProductDiscountView` no longer relies on it
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

    /// The opacity of the product row based on the selected state.
    var rowOpacity: CGFloat {
        switch selectedState {
        case .unsupported: 0.7
        case .notSelected, .selected, .partiallySelected: 1
        }
    }

    /// Whether selection is enabled for the product row.
    var selectionEnabled: Bool {
        switch selectedState {
        case .unsupported: false
        case .notSelected, .selected, .partiallySelected: true
        }
    }

    /// Toggled selected value for when the row is tapped.
    /// If the row is currently selected, tapping it again should returns false for the toggled value and vice versa.
    /// Unsupported state returns false by default.
    var toggledSelectedValue: Bool {
        switch selectedState {
        case .selected, .unsupported: false
        case .notSelected, .partiallySelected: true
        }
    }

    /// Determines if Subscription-type product details should be shown
    ///
    var shouldShowProductSubscriptionsDetails: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationUI) &&
        productSubscriptionDetails != nil
    }

    /// Subscription settings extracted from product meta data for a Subscription-type Product, if any
    ///
    private(set) var productSubscriptionDetails: ProductSubscription?

    /// Description of the subscription billing details for a Subscription-type Product
    /// eg: "$60.00 / 2 months"
    ///
    var subscriptionBillingDetailsLabel: String {
        guard let subscriptionPrice = productSubscriptionDetails?.price,
              let subscriptionInterval = productSubscriptionDetails?.periodInterval,
              let subscriptionPeriod = productSubscriptionDetails?.period,
              let formattedPrice = currencyFormatter.formatAmount(subscriptionPrice) else {
            return ""
        }

        let subscriptionFrequency = {
            switch subscriptionInterval {
            case "1":
                return subscriptionPeriod.descriptionSingular
            default:
                return subscriptionPeriod.descriptionPlural
            }
        }()
        return String.localizedStringWithFormat(Localization.Subscription.formattedBilling,
                                                formattedPrice, subscriptionInterval, subscriptionFrequency)
    }

    /// Description of the subscription conditions for a Subscription-type Product
    /// These are separate from each other, a subscription could have any, all, or none
    /// eg: "$25.00 signup · 1 month free"
    ///
    var subscriptionConditionsLabel: String {
        // Signup fees
        var formattedSignUpFee: String = ""

        if let signUpFee = productSubscriptionDetails?.signUpFee, !signUpFee.isEmpty, signUpFee != "0" {
            formattedSignUpFee = currencyFormatter.formatAmount(signUpFee) ?? ""
        }

        // Trial periods
        let trialLength = productSubscriptionDetails?.trialLength ?? ""
        let trialPeriod = productSubscriptionDetails?.trialPeriod

        let formattedTrialDetails = {
            // If trial period is missing, we can skip formatting the rest
            guard let trialPeriod = trialPeriod else { return "" }
            switch trialLength {
            case "", "0":
                // The API allows empty and 0 as values for trial length, with a non-nil trial period.
                // eg: "every -empty- days", or "every 0 days"
                return ""
            case "1":
                return trialPeriod.descriptionSingular
            default:
                return trialPeriod.descriptionPlural
            }
        }()

        let hasNoSignUpFees = formattedSignUpFee.isEmpty
        let hasNoFreeTrial = formattedTrialDetails.isEmpty

        switch (hasNoSignUpFees, hasNoFreeTrial) {
        case (true, true):
            return ""
        case (true, false):
            return String.localizedStringWithFormat(Localization.Subscription.formattedConditionsWithoutSignup, trialLength, formattedTrialDetails)
        case (false, true):
            return String.localizedStringWithFormat(Localization.Subscription.formattedConditionsWithoutTrial, formattedSignUpFee)
        case (false, false):
            return String.localizedStringWithFormat(Localization.Subscription.formattedConditions,
                                                    formattedSignUpFee, trialLength, formattedTrialDetails)
        }
    }

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

    private(set) var discount: Decimal?

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
        if case .unsupported(let unsupportedReason) = selectedState {
            unsupportedReason
        } else if productSubscriptionDetails != nil {
            [stockOrAttributesLabel, skuLabel, variationsLabel]
                .compactMap({ $0 })
                .filter { $0.isNotEmpty }
                .joined(separator: " • ")
        } else {
            [stockOrAttributesLabel, priceAndDiscountsLabel, variationsLabel]
                .compactMap({ $0 })
                .joined(separator: " • ")
        }
    }

    /// Label showing secondary product details. Can include product type (if the row is configurable), and SKU (if available).
    ///
    var secondaryProductDetailsLabel: String {
        if case .unsupported(let reason) = selectedState {
            return ""
        }

        var labels = [productTypeLabel]
        // Only add the SKU label to the secondary product details when there are no
        // product subscription details
        if productSubscriptionDetails == nil {
            labels.append(skuLabel)
        }

        return labels
            .compactMap({ $0 })
            .filter { $0.isNotEmpty }
            .joined(separator: " • ")
    }

    private let productTypeLabel: String?

    /// Label showing product SKU
    ///
    private(set) lazy var skuLabel: String = {
        guard let sku = sku, sku.isNotEmpty else {
            return ""
        }
        return String.localizedStringWithFormat(Localization.skuFormat, sku)
    }()

    /// Custom accessibility label for product.
    ///
    var productAccessibilityLabel: String {
        if case .unsupported(let reason) = selectedState {
            return [name, reason].joined(separator: ". ")
        }
        return [name, stockOrAttributesLabel, priceAndDiscountsLabel, variationsLabel, skuLabel]
            .compactMap({ $0 })
            .joined(separator: ". ")
    }

    /// Quantity of product in the order. The source of truth is from the the quantity stepper view model `stepperViewModel`.
    ///
    @Published var quantity: Decimal

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
         imageURL: URL?,
         numberOfVariations: Int = 0,
         variationDisplayMode: VariationDisplayMode? = nil,
         productSubscriptionDetails: ProductSubscription? = nil,
         selectedState: ProductRow.SelectedState = .notSelected,
         pricedIndividually: Bool = true,
         isConfigurable: Bool,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         analytics: Analytics = ServiceLocator.analytics,
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
        self.imageURL = imageURL
        self.pricedIndividually = pricedIndividually
        self.isConfigurable = isConfigurable
        self.currencyFormatter = currencyFormatter
        self.analytics = analytics
        self.numberOfVariations = numberOfVariations
        self.variationDisplayMode = variationDisplayMode
        self.productSubscriptionDetails = productSubscriptionDetails
        self.configure = configure
    }

    /// Initialize `ProductRowViewModel` with a `Product`
    ///
    convenience init(id: Int64? = nil,
                     product: Product,
                     discount: Decimal? = nil,
                     quantity: Decimal = 1,
                     productSubscriptionDetails: ProductSubscription? = nil,
                     selectedState: ProductRow.SelectedState = .notSelected,
                     pricedIndividually: Bool = true,
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     analytics: Analytics = ServiceLocator.analytics,
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

        // If product is a product bundle with insufficient bundle stock, use that as the product stock status.
        let stockStatusKey: String = {
            switch (product.productType, product.bundleStockStatus) {
            case (.bundle, .insufficientStock):
                return ProductStockStatus.insufficientStock.rawValue
            default:
                return product.stockStatusKey
            }
        }()

        // If product is a product bundle with a bundle stock quantity, use that as the product stock quantity.
        let stockQuantity: Decimal? = {
            switch (product.productType, product.bundleStockQuantity) {
            case (.bundle, .some(let bundleStockQuantity)):
                return Decimal(bundleStockQuantity)
            default:
                return product.stockQuantity
            }
        }()

        // If product is a product bundle with a bundle stock quantity, override product `manageStock` setting.
        let manageStock: Bool = {
            switch (product.productType, product.bundleStockQuantity) {
            case (.bundle, .some):
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

        let productSubscriptionDetails: ProductSubscription?
        if product.productType == .subscription || product.productType == .variableSubscription {
            productSubscriptionDetails = product.subscription
        } else {
            productSubscriptionDetails = nil
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
                  imageURL: product.imageURL,
                  numberOfVariations: product.variations.count,
                  productSubscriptionDetails: productSubscriptionDetails,
                  selectedState: selectedState,
                  pricedIndividually: pricedIndividually,
                  isConfigurable: isConfigurable,
                  currencyFormatter: currencyFormatter,
                  analytics: analytics,
                  configure: configure)
    }

    /// Initialize `ProductRowViewModel` with a `ProductVariation`
    ///
    convenience init(id: Int64? = nil,
                     productVariation: ProductVariation,
                     discount: Decimal? = nil,
                     name: String,
                     quantity: Decimal = 1,
                     productSubscriptionDetails: ProductSubscription? = nil,
                     displayMode: VariationDisplayMode,
                     selectedState: ProductRow.SelectedState = .notSelected,
                     pricedIndividually: Bool = true,
                     currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
                     analytics: Analytics = ServiceLocator.analytics) {
        let imageURL: URL?
        if let encodedImageURLString = productVariation.image?.src.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            imageURL = URL(string: encodedImageURLString)
        } else {
            imageURL = nil
        }

        // Checks if the product variation contains Subscription-type Product meta data
        let productSubscriptionDetails: ProductSubscription?
        if productVariation.subscription != nil {
            productSubscriptionDetails = productVariation.subscription
        } else {
            productSubscriptionDetails = nil
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
                  imageURL: imageURL,
                  variationDisplayMode: displayMode,
                  productSubscriptionDetails: productSubscriptionDetails,
                  selectedState: selectedState,
                  pricedIndividually: pricedIndividually,
                  isConfigurable: false,
                  currencyFormatter: currencyFormatter,
                  analytics: analytics)
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
}

private extension ProductRowViewModel {
    enum Localization {
        static let stockFormat = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        static let singleVariation = NSLocalizedString("%ld variation",
                                                       comment: "Label for one product variation when showing details about a variable product")
        static let pluralVariations = NSLocalizedString("%ld variations",
                                                        comment: "Label for multiple product variations when showing details about a variable product")

        enum Subscription {
            static let formattedBilling = NSLocalizedString(
                "ProductRowViewModel.formattedProductSubscriptionBilling",
                value: "%1$@ / %2$@ %3$@",
                comment: "Description of the subscription price for a product, with price and billing frequency. " +
                "Reads as: '$60.00 / 2 months'.")
            static let formattedConditions = NSLocalizedString(
                "ProductRowViewModel.formattedProductSubscriptionConditions",
                value: "%1$@ signup · %2$@ %3$@ free",
                comment: "Description of the subscription conditions for a subscription product, with signup fees and free trials." +
                "Reads as: '$25.00 signup · 1 month free'.")
            static let formattedConditionsWithoutSignup = NSLocalizedString(
                "ProductRowViewModel.formattedProductSubscriptionConditionsWithoutSignup",
                value: "%1$@ %2$@ free",
                comment: "Description of the subscription conditions for a subscription product, with only free trial." +
                "Reads as: '1 month free'.")
            static let formattedConditionsWithoutTrial = NSLocalizedString(
                "ProductRowViewModel.formattedProductSubscriptionConditionsWithoutTrial",
                value: "%1$@ signup",
                comment: "Description of the subscription conditions for a subscription product, with signup fees but no trial." +
                "Reads as: '$25.00 signup'.")
        }
    }
}
