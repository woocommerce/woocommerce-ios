import UIKit
import SwiftUI
import Kingfisher

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
    @ObservedObject var viewModel: BundledProductsListViewModel

    /// Dynamic image width, also used for its height.
    ///
    @ScaledMetric private var imageWidth = Layout.standardImageWidth

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.bundledProducts) { bundledProduct in
                    HStack {
                        KFImage(bundledProduct.imageURL)
                            .placeholder {
                                Image(uiImage: .productPlaceholderImage)
                                    .foregroundColor(Color(.listIcon))
                            }
                            .resizable()
                            .frame(width: imageWidth, height: imageWidth)
                            .cornerRadius(Layout.imageCornerRadius)
                            .accessibilityHidden(true)
                            .padding(.leading)

                        TitleAndSubtitleRow(title: bundledProduct.title, subtitle: bundledProduct.stockStatus)
                    }
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

private enum Layout {
    static let standardImageWidth: CGFloat = 48.0
    static let imageCornerRadius: CGFloat = 4.0
}


// MARK: Previews
struct BundledProductsList_Previews: PreviewProvider {

    static let viewModel = BundledProductsListViewModel(bundledProducts: [
        .init(id: 1, title: "Beanie with Logo", stockStatus: "In stock", imageURL: nil),
        .init(id: 2, title: "T-Shirt with Logo", stockStatus: "In stock", imageURL: nil),
        .init(id: 3, title: "Hoodie with Logo", stockStatus: "Out of stock", imageURL: nil)
    ])

    static var previews: some View {
        BundledProductsList(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        BundledProductsList(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        BundledProductsList(viewModel: viewModel)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font")
    }
}
