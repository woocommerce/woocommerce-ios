import UIKit
import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps an `ProductAddOnsList` view.
///
final class ProductAddOnsListViewController: UIHostingController<ProductAddOnsList> {
    init(viewModel: ProductAddOnsListViewModel) {
        super.init(rootView: ProductAddOnsList())
        title = viewModel.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders a list of product add-ons
///
struct ProductAddOnsList: View {
    var body: some View {
        Text("WIP")
    }
}

// MARK: Previews
struct ProductAddOnsList_Previews: PreviewProvider {
    static var previews: some View {
        ProductAddOnsList()
            .environment(\.colorScheme, .light)
    }
}
