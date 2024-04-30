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

    /// Product price
    ///
    let price: String?

    /// Product discount
    ///
    let discount: Decimal?

    /// Label showing product details for an order item.
    /// Can include product type (if the row is configurable), variation attributes (if available), and stock status.
    ///
    let productDetailsLabel: String

    let stepperViewModel: ProductStepperViewModel
    let priceSummaryViewModel: CollapsibleProductCardPriceSummaryViewModel

    /// Subscription settings extracted from product meta data for a Subscription-type Product, if any
    ///
    private(set) var productSubscriptionDetails: ProductSubscription?

    private let currencyFormatter: CurrencyFormatter
    private let analytics: Analytics

    /// Determines if Subscription-type product details should be shown
    ///
    var shouldShowProductSubscriptionsDetails: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationUI) &&
        productSubscriptionDetails != nil
    }

    /// Description of the subscription billing interval for a Subscription-type Product
    /// eg: "Every 2 months"
    ///
    var subscriptionBillingIntervalLabel: String? {
        guard let periodInterval = productSubscriptionDetails?.periodInterval,
              periodInterval != "0",
              let period = productSubscriptionDetails?.period else {
            return nil
        }

        let pluralizedPeriod = {
            switch periodInterval {
            case "1":
                return period.descriptionSingular
            default:
                return period.descriptionPlural
            }
        }()

        return String.localizedStringWithFormat(Localization.Subscription.formattedBillingDetails,
                                                periodInterval,
                                                pluralizedPeriod)
    }

    /// Subscription final price for a Subscription-type Product. Acounts for pricing modifications like "on-sale" pricing, and quantity
    /// eg: Displays "$30.00" for 10 subscriptions of "$3.00" of regular price each
    /// eg: Displays "$20.00" for 10 subscriptions of "$2.00" of on-sale price each
    ///
    var subscriptionPrice: String? {
        // The price could be different from the subscription price if there are price modifiers, like on sale pricing.
        // In this case, we use the product price, not the subscription price within the subscription metadata
        var pricePerUnit: String
        guard let subscriptionRegularPrice = productSubscriptionDetails?.price,
              subscriptionRegularPrice != "0",
              let productPrice = price else {
            return nil
        }
        if productPrice != subscriptionRegularPrice {
            pricePerUnit = productPrice
        } else {
            pricePerUnit = subscriptionRegularPrice
        }
        return pricePerQuantity(price: pricePerUnit)
    }

    /// Description of the subscription sign up fee for a Subscription-type Product
    /// eg: "$0.50"
    ///
    var subscriptionConditionsSignupFee: String? {
        guard let signupFee = productSubscriptionDetails?.signUpFee,
              signupFee.isNotEmpty,
              signupFee != "0" else {
            return nil
        }
        return pricePerQuantity(price: signupFee)
    }

    /// Summary of the subscription sign up fees for a Subscription-type Product when an order has more than one
    /// eg: "3 x $0.60"
    ///
    var signupFeeSummary: String? {
        guard let subscriptionConditionsSignupFee, stepperViewModel.quantity > 1 else {
            return nil
        }
        let quantity = stepperViewModel.quantity.formatted()
        return String.localizedStringWithFormat(Localization.Subscription.signupFeeSummary,
                                                quantity,
                                                subscriptionConditionsSignupFee)
    }

    /// Label of the subscription sign up fee for a Subscription-type Product
    /// eg: "$0.50 signup"
    ///
    var subscriptionConditionsSignupLabel: String? {
        guard let subscriptionConditionsSignupFee else {
            return nil
        }
        return String.localizedStringWithFormat(Localization.Subscription.formattedSignUpFee,
                                                subscriptionConditionsSignupFee)
    }

    var subscriptionConditionsFreeTrialLabel: String? {
        // Trial length or period could be nil. Trial length could be zero or empty.
        // In both cases, the free trial conditions are invalid and should return no label.
        guard let trialLength = productSubscriptionDetails?.trialLength,
              let trialPeriod = productSubscriptionDetails?.trialPeriod,
              trialLength.isNotEmpty,
              trialLength != "0" else {
            return nil
        }

        let pluralizedTrialPeriod = {
            switch trialLength {
            case "1":
                return trialPeriod.descriptionSingular
            default:
                return trialPeriod.descriptionPlural
            }
        }()

        return String.localizedStringWithFormat(Localization.Subscription.formattedFreeTrial,
                                                trialLength,
                                                pluralizedTrialPeriod)
    }

    var subscriptionConditionsDetailsLabel: String {
        [subscriptionConditionsSignupLabel, subscriptionConditionsFreeTrialLabel]
            .compactMap({ $0 })
            .filter({ $0.isNotEmpty })
            .joined(separator: " · ")
    }

    init(id: Int64,
         productOrVariationID: Int64,
         hasParentProduct: Bool = false,
         isReadOnly: Bool = false,
         isConfigurable: Bool = false,
         productSubscriptionDetails: ProductSubscription? = nil,
         imageURL: URL?,
         name: String,
         sku: String?,
         price: String?,
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
        self.productSubscriptionDetails = productSubscriptionDetails
        self.configure = configure
        self.imageURL = imageURL
        self.name = name
        self.price = price
        self.discount = discount
        skuLabel = CollapsibleProductRowCardViewModel.createSKULabel(sku: sku)
        productDetailsLabel = CollapsibleProductRowCardViewModel.createProductDetailsLabel(isConfigurable: isConfigurable,
                                                                                           productTypeDescription: productTypeDescription,
                                                                                           attributes: attributes,
                                                                                           stockStatus: stockStatus,
                                                                                           stockQuantity: stockQuantity,
                                                                                           manageStock: manageStock)
        self.stepperViewModel = stepperViewModel
        self.priceSummaryViewModel = .init(pricedIndividually: pricedIndividually,
                                           isSubscriptionProduct: (productSubscriptionDetails != nil),
                                           quantity: stepperViewModel.quantity,
                                           price: price)
        self.currencyFormatter = currencyFormatter
        self.analytics = analytics

        observeProductQuantityFromStepperViewModel()
    }

    func trackAddDiscountTapped() {
        analytics.track(event: .Orders.productDiscountAddButtonTapped())
    }

    func trackEditDiscountTapped() {
        analytics.track(event: .Orders.productDiscountEditButtonTapped())
    }
}

extension CollapsibleProductRowCardViewModel {
    /// Returns the total price by multiplying price per quantity
    ///
    private func pricePerQuantity(price: String) -> String? {
        let quantity = stepperViewModel.quantity
        guard let decimalPrice = currencyFormatter.convertToDecimal(price)?.decimalValue,
              let stringTotal =  currencyFormatter.formatHumanReadableAmount(decimalPrice * quantity, roundSmallNumbers: false) else {
            return nil
        }
        let formattedPrice = currencyFormatter.formatAmount(stringTotal)
        return formattedPrice
    }

    /// Formatted price label based on a product's price and quantity. Accounting for discounts, if any.
    /// e.g: If price is $5, quantity is 10, and discount is $1, outputs "$49.00"
    ///
    var totalPriceAfterDiscountLabel: String? {
        guard let price,
              let priceDecimal = currencyFormatter.convertToDecimal(price) else {
            return nil
        }
        let subtotalDecimal = priceDecimal.multiplying(by: stepperViewModel.quantity as NSDecimalNumber)
        let totalPriceAfterDiscount = subtotalDecimal.subtracting((discount ?? Decimal.zero) as NSDecimalNumber)

        return currencyFormatter.formatAmount(totalPriceAfterDiscount)
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
        enum Subscription {
            static let formattedBillingDetails = NSLocalizedString(
                "CollapsibleProductRowCardViewModel.formattedBillingDetails",
                value: "Every %1$@ %2$@",
                comment: "Description of the billing and billing frequency for a subscription product. " +
                "Reads as: 'Every 2 months'.")
            static let formattedSignUpFee = NSLocalizedString(
                "CollapsibleProductRowCardViewModel.formattedSignUpFee",
                value: "%1$@ signup",
                comment: "Description of the signup fees for a subscription product. " +
                "Reads as: '$5.00 signup'.")
            static let formattedFreeTrial = NSLocalizedString(
                "CollapsibleProductRowCardViewModel.formattedFreeTrial",
                value: "%1$@ %2$@ free",
                comment: "Description of the free trial conditions for a subscription product. " +
                "Reads as: '3 days free'.")
            static let signupFeeSummary = NSLocalizedString(
                "CollapsibleProductRowCardViewModel.signupFeeSummary",
                value: "%1$@ × %2$@",
                comment: "Summary of quantity and signup fees for a subscription product when multiple are selected." +
                "Reads as: '3 × $0.60'. Please ensure you use a multiplication symbol, not a letter x")
        }
    }
}
