import UIKit
import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps a `BundledProductsList` view.
///
final class BundledProductsListViewController: UIHostingController<BundledProductsList> {
    init(viewModel: BundledProductsListViewModel) {
        super.init(rootView: BundledProductsList(viewModel: viewModel))
        title = viewModel.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders a list of bundled products in a product bundle
///
struct BundledProductsList: View {

    /// View model that directs the view content.
    ///
    let viewModel: BundledProductsListViewModel

    var body: some View {
        ScrollView {
            Group {
                TitleAndSubtitleRow(title: "Beanie with Logo", subtitle: "In stock")
                Divider().padding(.leading)
                TitleAndSubtitleRow(title: "T-Shirt with Logo", subtitle: "In stock")
                Divider().padding(.leading)
                TitleAndSubtitleRow(title: "Hoodie with Logo", subtitle: "Out of stock")
                Divider().padding(.leading)
            }.background(Color(.listForeground(modal: false)))
        }
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}


// MARK: Previews
struct BundledProductsList_Previews: PreviewProvider {

    static let viewModel = BundledProductsListViewModel()

    static var previews: some View {
        BundledProductsList(viewModel: viewModel)
            .environment(\.colorScheme, .light)
    }
}
