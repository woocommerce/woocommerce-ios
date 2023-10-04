import SwiftUI

struct CollapsibleProductRowCard: View {

    @ObservedObject var viewModel: ProductRowViewModel
    @State private var isCollapsed: Bool = true

    init(viewModel: ProductRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        CollapsibleView(isCollapsible: true, isCollapsed: $isCollapsed, safeAreaInsets: EdgeInsets(), label: {
            VStack {
                HStack(alignment: .center, spacing: Layout.padding) {
                    Image(systemName: "photo.stack.fill")
                    VStack(alignment: .leading) {
                        Text(viewModel.name)
                        Text("29 in stock")
                            .foregroundColor(.gray)
                        CollapsibleProductCardPriceSummary(viewModel: viewModel)
                    }
                }
            }

        }, content: {
            ProductRow(shouldShowImageThumbnail: false, viewModel: viewModel)
        })
    }
}

struct CollapsibleProductCardPriceSummary: View {

    @ObservedObject var viewModel: ProductRowViewModel

    init(viewModel: ProductRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            HStack {
                Text(viewModel.quantity.formatted())
                    .foregroundColor(.gray)
                Text("x")
                    .foregroundColor(.gray)
                Text(viewModel.priceLabel ?? "-")
                    .foregroundColor(.gray)
                Spacer()
            }
            Text("$45.00")
        }
    }
}

private enum Layout {
    static let padding: CGFloat = 16
}
