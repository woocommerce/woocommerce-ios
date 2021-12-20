import Yosemite

final class ProductInOrderViewModel {

    /// The product being edited.
    ///
    let productRowViewModel: ProductRowViewModel

    /// Closure invoked when the product is removed.
    ///
    let onRemoveProduct: () -> Void

    init(productRowViewModel: ProductRowViewModel,
         onRemoveProduct: @escaping () -> Void) {
        self.productRowViewModel = productRowViewModel
        self.onRemoveProduct = onRemoveProduct
    }

    convenience init(product: Product,
         onRemoveProduct: @escaping () -> Void) {
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)
        self.init(productRowViewModel: viewModel,
                  onRemoveProduct: onRemoveProduct)
    }
}
