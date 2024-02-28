import Foundation
import SwiftUI

/// Hosting controller for `ProductSelectorView`.
///
final class ProductSelectorViewController: UIHostingController<ProductSelectorView> {
    init(configuration: ProductSelectorView.Configuration,
         source: ProductSelectorView.Source,
         viewModel: ProductSelectorViewModel) {

        super.init(rootView: ProductSelectorView(configuration: configuration,
                                                 source: source,
                                                 isPresented: .constant(true),
                                                 viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
