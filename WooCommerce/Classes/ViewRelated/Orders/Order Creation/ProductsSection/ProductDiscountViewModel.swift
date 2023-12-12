import Foundation
import WooFoundation
import Combine

final class ProductDiscountViewModel: Identifiable {
    // MARK: Product Details

    /// Product image
    let imageURL: URL?

    /// Product name
    let name: String

    /// View model for `CollapsibleProductCardPriceSummary`
    let priceSummary: CollapsibleProductCardPriceSummaryViewModel

    // MARK: Discount
    /// Encapsulates the necessary information to execute adding discounts to products
    ///
    struct DiscountConfiguration {
        let addedDiscount: Decimal
        let baseAmountForDiscountPercentage: Decimal
        let onSaveFormattedDiscount: (String?) -> Void
    }

    /// Discount added to the product
    let addedDiscount: Decimal

    /// The base amount to apply percentage fee or discount on
    let baseAmountForDiscountPercentage: Decimal

    /// Discount formatted with the store currency
    var formattedDiscount: String? {
        currencyFormatter.formatAmount(addedDiscount)
    }

    /// Closure to perform when the formatted discount is saved
    let onSaveFormattedDiscount: (String?) -> Void

    /// Publisher to fire when the view is dismissed
    var viewDismissPublisher = PassthroughSubject<(), Never>()

    let productRowViewModel: ProductRowViewModel

    private let currencyFormatter: CurrencyFormatter

    init(imageURL: URL?,
         name: String,
         priceSummary: CollapsibleProductCardPriceSummaryViewModel,
         discountConfiguration: DiscountConfiguration?,
         productRowViewModel: ProductRowViewModel,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.imageURL = imageURL
        self.name = name
        self.priceSummary = priceSummary
        addedDiscount = discountConfiguration?.addedDiscount ?? .zero
        baseAmountForDiscountPercentage = discountConfiguration?.baseAmountForDiscountPercentage ?? .zero
        onSaveFormattedDiscount = discountConfiguration?.onSaveFormattedDiscount ?? { _ in }
        self.productRowViewModel = productRowViewModel
        self.currencyFormatter = currencyFormatter
    }

    /// View model used for the `DiscountLineDetailsView`
    lazy var discountDetailsViewModel: FeeOrDiscountLineDetailsViewModel = {
        FeeOrDiscountLineDetailsViewModel(isExistingLine: addedDiscount != 0,
                                          baseAmountForPercentage: baseAmountForDiscountPercentage,
                                          initialTotal: formattedDiscount ?? "0",
                                          lineType: .discount,
                                          didSelectSave: { [weak self] formattedAmount in
            self?.onSaveFormattedDiscount(formattedAmount)
            self?.viewDismissPublisher.send(())
        })
    }()
}
