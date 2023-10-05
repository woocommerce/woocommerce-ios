import Yosemite
import SwiftUI
import Kingfisher

struct CollapsibleProductRowCard: View {
    @ObservedObject var viewModel: ProductRowViewModel
    @State private var isCollapsed: Bool = true

    @ScaledMetric private var scale: CGFloat = 1

    var onRemoveProduct: () -> Void

    private var isExpanded: Binding<Bool> {
        Binding<Bool>(
            get: { !self.isCollapsed },
            set: { self.isCollapsed = !$0 }
        )
    }

    private var imageProcessor: ImageProcessor {
        ResizingImageProcessor(referenceSize:
                .init(width: Layout.productImageSize * scale,
                      height: Layout.productImageSize * scale),
                               mode: .aspectFill
        )
    }

    init(viewModel: ProductRowViewModel, onRemoveProduct: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onRemoveProduct = onRemoveProduct
    }

    var body: some View {
        CollapsibleView(isCollapsible: true,
                        isCollapsed: $isCollapsed,
                        safeAreaInsets: EdgeInsets(),
                        shouldShowDividers: isExpanded,
                        label: {
            VStack {
                HStack(alignment: .center, spacing: Layout.padding) {
                    KFImage.url(viewModel.imageURL)
                        .placeholder {
                            Image(uiImage: .productPlaceholderImage)
                        }
                        .setProcessor(imageProcessor)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Layout.productImageSize * scale, height: Layout.productImageSize * scale)
                        .cornerRadius(Layout.productImageCornerRadius)
                        .foregroundColor(Color(UIColor.listSmallIcon))
                        .accessibilityHidden(true)
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
                onRemoveProduct()
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
        static let productImageSize: CGFloat = 56.0
        static let productImageCornerRadius: CGFloat = 4.0
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
        CollapsibleProductRowCard(viewModel: viewModel, onRemoveProduct: {})
    }
}
#endif
