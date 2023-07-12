import Yosemite
import WooFoundation

/// View model for `ProductInOrder`.
///
final class ProductInOrderViewModel: Identifiable {
    /// The product being edited.
    ///
    let productRowViewModel: ProductRowViewModel

    let addedDiscount: Decimal

    let baseAmountForDiscountPercentage: Decimal

    /// Currency symbol to display with amount text field
    ///
    let currencySymbol: String

    /// Closure invoked when the product is removed.
    ///
    let onRemoveProduct: () -> Void

    private let isAddingDiscountToProductEnabled: Bool

    var showAddDiscountRow: Bool {
        isAddingDiscountToProductEnabled && addedDiscount == 0
    }

    let onSaveFormattedDiscount: (String?) -> Void

    init(productRowViewModel: ProductRowViewModel,
         addedDiscount: Decimal,
         baseAmountForDiscountPercentage: Decimal,
         onRemoveProduct: @escaping () -> Void,
         onSaveFormattedDiscount: @escaping (String?) -> Void,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         isAddingDiscountToProductEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.ordersWithCouponsM4)) {
        self.productRowViewModel = productRowViewModel
        self.currencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.addedDiscount = addedDiscount
        self.baseAmountForDiscountPercentage = baseAmountForDiscountPercentage
        self.onRemoveProduct = onRemoveProduct
        self.onSaveFormattedDiscount = onSaveFormattedDiscount
        self.isAddingDiscountToProductEnabled = isAddingDiscountToProductEnabled
    }

    lazy var discountDetailsViewModel: FeeOrDiscountLineDetailsViewModel = {
        FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                          baseAmountForPercentage: baseAmountForDiscountPercentage,
                                          initialTotal: "0.00",
                                          lineType: .discount,
                                          didSelectSave: onSaveFormattedDiscount)
    }()
}
