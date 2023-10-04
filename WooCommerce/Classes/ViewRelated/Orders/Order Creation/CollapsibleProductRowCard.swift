import Yosemite
import SwiftUI

struct CollapsibleProductRowCard: View {
    @ObservedObject var viewModel: ProductRowViewModel
    @State private var isCollapsed: Bool = true

    private var isExpanded: Binding<Bool> {
        Binding<Bool>(
            get: { !self.isCollapsed },
            set: { self.isCollapsed = !$0 }
        )
    }

    init(viewModel: ProductRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        CollapsibleView(isCollapsible: true,
                        isCollapsed: $isCollapsed,
                        safeAreaInsets: EdgeInsets(),
                        shouldShowDividers: isExpanded,
                        label: {
            VStack {
                HStack(alignment: .center, spacing: Layout.padding) {
                    Image(systemName: "photo.stack.fill")
                    VStack(alignment: .leading) {
                        Text(viewModel.name)
                        Text(viewModel.stockQuantityLabel)
                            .foregroundColor(.gray)
                            .renderedIf(isCollapsed)
                        Text(viewModel.skuLabel)
                            .foregroundColor(.gray)
                            .renderedIf(!isCollapsed)
                        CollapsibleProductCardPriceSummary(viewModel: viewModel)
                    }
                }
            }

        }, content: {
            SimplifiedProductRow(viewModel: viewModel)
            HStack {
                Text(Localization.priceLabel)
                CollapsibleProductCardPriceSummary(viewModel: viewModel)
            }
            Divider()
                .padding()
            Button(Localization.removeProductLabel) {
                // TODO gh-10834: Action to remove product
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(Color(.error))
        })
        .padding(Layout.padding)
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay {
            RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                .inset(by: 0.25)
                .stroke(isCollapsed ? Color(uiColor: .separator) : Color(uiColor: .black),
                        lineWidth: Layout.borderLineWidth)
        }
        .cornerRadius(Layout.frameCornerRadius)
    }
}

private struct CollapsibleProductCardPriceSummary: View {

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
            if let price = viewModel.priceBeforeDiscountsLabel {
                Text(price)
            }
        }
    }
}

private extension CollapsibleProductRowCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
    }

    enum Localization {
        static let priceLabel = NSLocalizedString(
            "Price",
            comment: "Text in the product row card that indicating the price of the product")
        static let removeProductLabel = NSLocalizedString(
            "Remove Product from order",
            comment: "Text in the product row card button to remove a product from the current order")
    }
}

#if DEBUG
struct CollapsibleProductRowCard_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product.swiftUIPreviewSample()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)
        CollapsibleProductRowCard(viewModel: viewModel)
    }
}
#endif
