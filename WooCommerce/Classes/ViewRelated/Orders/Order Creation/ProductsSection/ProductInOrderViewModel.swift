import Yosemite

/// View model for `ProductInOrder`.
///
final class ProductInOrderViewModel: Identifiable {
    /// The product being edited.
    ///
    let productRowViewModel: ProductRowViewModel

    /// Closure invoked when the product is removed.
    ///
    let onRemoveProduct: () -> Void

    let isAddingDiscountToProductEnabled: Bool

    let onSaveFormattedDiscount: (String?) -> Void

    init(productRowViewModel: ProductRowViewModel,
         onRemoveProduct: @escaping () -> Void,
         onSaveFormattedDiscount: @escaping (String?) -> Void,
         isAddingDiscountToProductEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.ordersWithCouponsM4)) {
        self.productRowViewModel = productRowViewModel
        self.onRemoveProduct = onRemoveProduct
        self.onSaveFormattedDiscount = onSaveFormattedDiscount
        self.isAddingDiscountToProductEnabled = isAddingDiscountToProductEnabled
    }

    lazy var discountDetailsViewModel: FeeOrDiscountLineDetailsViewModel = {
        FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                          baseAmountForPercentage: 50,
                                          total: "0.00",
                                          lineType: .discount,
                                          didSelectSave: onSaveFormattedDiscount)
    }()
}
