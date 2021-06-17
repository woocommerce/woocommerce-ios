import UIKit
import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps an `ProductAddOnsList` view.
///
final class ProductAddOnsListViewController: UIHostingController<ProductAddOnsList> {
    init(viewModel: ProductAddOnsListViewModel) {
        super.init(rootView: ProductAddOnsList(viewModel: viewModel))
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

    /// View model that directs the view content.
    ///
    let viewModel: ProductAddOnsListViewModel

    var body: some View {
        AddOnListNotice(updateText: viewModel.infoNotice)
    }
}

/// Renders a info notice with an icon
///
private struct AddOnListNotice: View {

    /// Content to be rendered next to the info icon.
    ///
    let updateText: String

    var body: some View {
        HStack {
            Image(uiImage: .infoOutlineImage)
            Text(updateText)
        }
        .footnoteStyle()
        .padding([.leading, .trailing]).padding(.top, 4)
    }
}


// MARK: Previews
struct ProductAddOnsList_Previews: PreviewProvider {
    static var previews: some View {
        ProductAddOnsList(viewModel: ProductAddOnsListViewModel())
            .environment(\.colorScheme, .light)
    }
}
