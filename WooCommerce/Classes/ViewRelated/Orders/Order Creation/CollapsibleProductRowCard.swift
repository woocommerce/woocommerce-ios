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
                        Text(viewModel.stockQuantityLabel)
                            .foregroundColor(.gray)
                        CollapsibleProductCardPriceSummary(viewModel: viewModel)
                    }
                }
            }

        }, content: {
            SimplifiedProductRow(viewModel: viewModel)
            HStack {
                Text("Price")
                CollapsibleProductCardPriceSummary(viewModel: viewModel)
            }
            Button("Remove Product from order") {
                // TODO gh-10834: Action to remove product
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(Color(.error))
            Divider()
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
            if let price = viewModel.priceLabel {
                Text(price)
            }
        }
    }
}

private enum Layout {
    static let padding: CGFloat = 16
}
