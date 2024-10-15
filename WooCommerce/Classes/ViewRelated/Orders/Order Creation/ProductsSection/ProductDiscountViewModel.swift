import Foundation
import WooFoundation
import Combine

final class ProductDiscountViewModel: Identifiable {
    /// Unique ID for the view model.
    ///
    let id: Int64

    // MARK: Product Details

    /// Product image
    let imageURL: URL?

    /// Product name
    let name: String

    /// Total product price with quantity excluding discount
    let totalPricePreDiscount: String?

    /// View model for `CollapsibleProductCardPriceSummary`
    let priceSummary: CollapsibleProductCardPriceSummaryViewModel

    // MARK: Discount
    /// Encapsulates the necessary information to execute adding discounts to products
    ///
    struct DiscountConfiguration {
        let addedDiscount: Decimal
        let baseAmountForDiscountPercentage: Decimal
        let onSave: (_ discount: Decimal?) -> Void
    }

    /// Whether there is already a discount on the product
    let hasDiscount: Bool

    /// Discount added to the product
    let addedDiscount: Decimal

    /// The base amount to apply percentage fee or discount on
    let baseAmountForDiscountPercentage: Decimal

    /// Discount formatted with the store currency
    var formattedDiscount: String? {
        currencyFormatter.formatAmount(addedDiscount)
    }

    /// Closure to perform when the formatted discount is saved
    let onSave: (_ discount: Decimal?) -> Void

    /// Publisher to fire when the view is dismissed
    var viewDismissPublisher = PassthroughSubject<(), Never>()

    private let currencyFormatter: CurrencyFormatter

    init(id: Int64,
         imageURL: URL?,
         name: String,
         totalPricePreDiscount: String?,
         priceSummary: CollapsibleProductCardPriceSummaryViewModel,
         discountConfiguration: DiscountConfiguration?,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.id = id
        self.imageURL = imageURL
        self.name = name
        self.totalPricePreDiscount = totalPricePreDiscount
        self.priceSummary = priceSummary
        addedDiscount = discountConfiguration?.addedDiscount ?? .zero
        hasDiscount = addedDiscount != 0
        baseAmountForDiscountPercentage = discountConfiguration?.baseAmountForDiscountPercentage ?? .zero
        onSave = discountConfiguration?.onSave ?? { _ in }
        self.currencyFormatter = currencyFormatter
    }

    /// View model used for the `DiscountLineDetailsView`
    private(set) lazy var discountDetailsViewModel: FeeOrDiscountLineDetailsViewModel = {
        FeeOrDiscountLineDetailsViewModel(isExistingLine: addedDiscount != 0,
                                          baseAmount: baseAmountForDiscountPercentage,
                                          initialTotal: addedDiscount,
                                          lineType: .discount,
                                          didSelectSave: { [weak self] discount in
            self?.onSave(discount)
            self?.viewDismissPublisher.send(())
        })
    }()
}
