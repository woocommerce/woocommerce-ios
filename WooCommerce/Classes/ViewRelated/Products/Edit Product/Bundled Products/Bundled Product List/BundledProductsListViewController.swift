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
            LazyVStack(spacing: 0) {
                ForEach(viewModel.bundledProducts) { bundledProduct in
                    TitleAndSubtitleRow(title: bundledProduct.title, subtitle: bundledProduct.stockStatus)
                    Divider().padding(.leading)
                }
            }
            .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: viewModel.infoNotice)
        }
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}


// MARK: Previews
struct BundledProductsList_Previews: PreviewProvider {

    static let viewModel = BundledProductsListViewModel(bundledProducts: [
        .init(id: 1, title: "Beanie with Logo", stockStatus: "In stock"),
        .init(id: 2, title: "T-Shirt with Logo", stockStatus: "In stock"),
        .init(id: 3, title: "Hoodie with Logo", stockStatus: "Out of stock")
    ])

    static var previews: some View {
        BundledProductsList(viewModel: viewModel)
            .environment(\.colorScheme, .light)
    }
}
