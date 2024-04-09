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

    var subscriptionBillingDetailsLabel: String {
        guard let periodInterval = productSubscriptionDetails?.periodInterval,
                let period = productSubscriptionDetails?.period else {
            return ""
        }

        let pluralizedPeriod = {
            switch periodInterval {
            case "1":
                return period.descriptionSingular
            default:
                return period.descriptionPlural
            }
        }

        return String.localizedStringWithFormat(Localization.formattedSubscriptionBillingDetailsLabel,
                                                periodInterval,
                                                pluralizedPeriod())
    }

    var subscriptionPrice: String {
        let currency = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)

        guard let price = productSubscriptionDetails?.price,
              let formattedPrice = currencyFormatter.formatAmount(price, with: currency) else {
            return ""
        }

        return formattedPrice
    }

    var subscriptionConditionsSignupFee: String? {
        let currency = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
        guard let signupFee = productSubscriptionDetails?.signUpFee else {
            return nil
        }

        let formattedSignupFee = currencyFormatter.formatAmount(signupFee, with: currency)
        return formattedSignupFee
    }

    var subscriptionConditionsSignupLabel: String? {
        guard let subscriptionConditionsSignupFee else {
            return nil
        }
        return String.localizedStringWithFormat(Localization.formattedSubscriptionSignUpFeeLabel,
                                                subscriptionConditionsSignupFee)
    }

    var subscriptionConditionsFreeTrialLabel: String? {
        guard let trialLength = productSubscriptionDetails?.trialLength,
              let trialPeriod = productSubscriptionDetails?.trialPeriod else {
            return nil
        }

        let pluralizedTrialPeriod = {
            switch trialLength {
            case "1":
                return trialPeriod.descriptionSingular
            default:
                return trialPeriod.descriptionPlural
            }
        }

        return String.localizedStringWithFormat(Localization.formattedSubscriptionFreeTrialLabel,
                                                trialLength,
                                                pluralizedTrialPeriod())
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
        static let formattedSubscriptionBillingDetailsLabel = NSLocalizedString(
            "CollapsibleProductRowCardViewModel.formattedSubscriptionBillingDetailsLabel",
            value: "Every %1$@ %2$@",
            comment: "Description of the billing and billing frequency for a subscription product. " +
            "Reads as: 'Every 2 months'.")
        static let formattedSubscriptionSignUpFeeLabel = NSLocalizedString(
            "CollapsibleProductRowCardViewModel.formattedSubscriptionSignUpFeeLabel",
            value: "%1$@ signup",
            comment: "Description of the signup fees for a subscription product. " +
            "Reads as: '$5.00 signup'.")
        static let formattedSubscriptionFreeTrialLabel = NSLocalizedString(
            "CollapsibleProductRowCardViewModel.formattedSubscriptionFreeTrialLabel",
            value: "%1$@ %2$@ free",
            comment: "Description of the free trial conditions for a subscription product. " +
            "Reads as: '3 days free'.")
    }
}
