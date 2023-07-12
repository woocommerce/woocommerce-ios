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

    init(productRowViewModel: ProductRowViewModel,
         onRemoveProduct: @escaping () -> Void,
         isAddingDiscountToProductEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.ordersWithCouponsM4)) {
        self.productRowViewModel = productRowViewModel
        self.onRemoveProduct = onRemoveProduct
        self.isAddingDiscountToProductEnabled = isAddingDiscountToProductEnabled
    }
}
