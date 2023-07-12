import Yosemite
import Combine
import WooFoundation

/// View model for `ProductInOrder`.
///
final class ProductInOrderViewModel: Identifiable {
    /// The product being edited.
    ///
    let productRowViewModel: ProductRowViewModel

    let addedDiscount: Decimal

    var formattedDiscount: String? {
        currencyFormatter.formatAmount(addedDiscount)
    }

    let baseAmountForDiscountPercentage: Decimal

    /// Closure invoked when the product is removed.
    ///
    let onRemoveProduct: () -> Void

    private let isAddingDiscountToProductEnabled: Bool

    var showAddDiscountRow: Bool {
        isAddingDiscountToProductEnabled && addedDiscount == 0
    }

    var showCurrentDiscountSection: Bool {
        isAddingDiscountToProductEnabled && addedDiscount != 0
    }

    let onSaveFormattedDiscount: (String?) -> Void

    var viewDismissPublisher = PassthroughSubject<(), Never>()

    private let currencyFormatter: CurrencyFormatter

    init(productRowViewModel: ProductRowViewModel,
         addedDiscount: Decimal,
         baseAmountForDiscountPercentage: Decimal,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         onRemoveProduct: @escaping () -> Void,
         onSaveFormattedDiscount: @escaping (String?) -> Void,
         isAddingDiscountToProductEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.ordersWithCouponsM4)) {
        self.productRowViewModel = productRowViewModel
        self.addedDiscount = addedDiscount
        self.baseAmountForDiscountPercentage = baseAmountForDiscountPercentage
        self.onRemoveProduct = onRemoveProduct
        self.onSaveFormattedDiscount = onSaveFormattedDiscount
        self.isAddingDiscountToProductEnabled = isAddingDiscountToProductEnabled
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
    }

    lazy var discountDetailsViewModel: FeeOrDiscountLineDetailsViewModel = {
        FeeOrDiscountLineDetailsViewModel(isExistingLine: addedDiscount > 0,
                                          baseAmountForPercentage: baseAmountForDiscountPercentage,
                                          initialTotal: formattedDiscount ?? "0",
                                          lineType: .discount,
                                          didSelectSave: { [weak self] formattedAmount in
            self?.onSaveFormattedDiscount(formattedAmount)
            self?.viewDismissPublisher.send(())
        })
    }()
}
