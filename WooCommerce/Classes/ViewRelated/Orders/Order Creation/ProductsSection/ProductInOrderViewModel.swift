import Yosemite

/// View model for `ProductInOrder`.
///
final class ProductInOrderViewModel: Identifiable {
    /// The product being edited.
    ///
    let productRowViewModel: ProductRowViewModel

    let baseAmountForDiscountPercentage: Decimal

    /// Closure invoked when the product is removed.
    ///
    let onRemoveProduct: () -> Void

    let isAddingDiscountToProductEnabled: Bool

    let onSaveFormattedDiscount: (String?) -> Void

    init(productRowViewModel: ProductRowViewModel,
         baseAmountForDiscountPercentage: Decimal,
         onRemoveProduct: @escaping () -> Void,
         onSaveFormattedDiscount: @escaping (String?) -> Void,
         isAddingDiscountToProductEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.ordersWithCouponsM4)) {
        self.productRowViewModel = productRowViewModel
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
