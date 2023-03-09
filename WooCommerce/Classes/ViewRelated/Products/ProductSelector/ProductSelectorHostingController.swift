import SwiftUI

/// Hosting controller that wraps `ProductSelectorView`.
final class ProductSelectorHostingController: UIHostingController<ProductSelectorView> {
    init(configuration: ProductSelectorView.Configuration,
         viewModel: ProductSelectorViewModel) {
        super.init(rootView: .init(configuration: configuration, isPresented: .constant(false), viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
