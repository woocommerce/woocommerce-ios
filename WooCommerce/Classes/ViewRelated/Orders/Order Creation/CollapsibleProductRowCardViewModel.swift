import Experiments
import SwiftUI
import WooFoundation
import Yosemite

/// View model for `CollapsibleProductCard`.
struct CollapsibleProductCardViewModel: Identifiable {
    var id: Int64 {
        productRow.productViewModel.id
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
    var id: Int64 {
        productViewModel.id
    }

    /// Whether a product in an order item has a parent order item
    let hasParentProduct: Bool

    /// Whether the product row is read-only. Defaults to `false`.
    ///
    /// Used to remove product editing controls for read-only order items (e.g. child items of a product bundle).
    let isReadOnly: Bool

    let productViewModel: ProductRowViewModel
    let stepperViewModel: ProductStepperViewModel
    let priceSummaryViewModel: CollapsibleProductCardPriceSummaryViewModel

    private let currencyFormatter: CurrencyFormatter
    private let analytics: Analytics

    init(hasParentProduct: Bool = false,
         isReadOnly: Bool = false,
         productViewModel: ProductRowViewModel,
         stepperViewModel: ProductStepperViewModel,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         analytics: Analytics = ServiceLocator.analytics) {
        self.hasParentProduct = hasParentProduct
        self.isReadOnly = isReadOnly
        self.productViewModel = productViewModel
        self.stepperViewModel = stepperViewModel
        self.priceSummaryViewModel = .init(pricedIndividually: productViewModel.pricedIndividually,
                                           quantity: stepperViewModel.quantity,
                                           price: productViewModel.price)
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
        guard let price = productViewModel.price,
              let priceDecimal = currencyFormatter.convertToDecimal(price) else {
            return nil
        }
        let subtotalDecimal = priceDecimal.multiplying(by: stepperViewModel.quantity as NSDecimalNumber)
        let totalPriceAfterDiscount = subtotalDecimal.subtracting((productViewModel.discount ?? Decimal.zero) as NSDecimalNumber)

        return currencyFormatter.formatAmount(totalPriceAfterDiscount)
    }

    /// Formatted discount label for an individual product
    ///
    var discountLabel: String? {
        guard let discount = productViewModel.discount else {
            return nil
        }
        return currencyFormatter.formatAmount(discount)
    }

    var hasDiscount: Bool {
        productViewModel.discount != nil
    }
}

private extension CollapsibleProductRowCardViewModel {
    func observeProductQuantityFromStepperViewModel() {
        stepperViewModel.$quantity
            .assign(to: &productViewModel.$quantity)
    }
}
