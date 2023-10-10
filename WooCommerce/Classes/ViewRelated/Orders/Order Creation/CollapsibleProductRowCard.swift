import Yosemite
import SwiftUI

struct CollapsibleProductRowCard: View {
    @ObservedObject var viewModel: ProductRowViewModel
    @State private var isCollapsed: Bool = true

    /// Indicates if the coupons informational tooltip should be shown or not.
    ///
    @State private var shouldShowCouponsInfoTooltip: Bool = false

    @ScaledMetric private var scale: CGFloat = 1

    var onAddDiscount: () -> Void

    private var shouldShowDividers: Bool {
        !isCollapsed
    }

    private let minusSign: String = NumberFormatter().minusSign

    init(viewModel: ProductRowViewModel, onAddDiscount: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onAddDiscount = onAddDiscount
    }

    var body: some View {
        CollapsibleView(isCollapsible: true,
                        isCollapsed: $isCollapsed,
                        safeAreaInsets: EdgeInsets(),
                        shouldShowDividers: shouldShowDividers,
                        label: {
            VStack {
                HStack(alignment: .center, spacing: Layout.padding) {
                    ProductImageThumbnail(productImageURL: viewModel.imageURL,
                                          productImageSize: Layout.productImageSize,
                                          scale: scale,
                                          productImageCornerRadius: Layout.productImageCornerRadius,
                                          foregroundColor: Color(UIColor.listSmallIcon))
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
            .padding(.bottom)
            HStack {
                discountRow
            }
            HStack {
                Text(Localization.priceAfterDiscountLabel)
                Spacer()
                Text(viewModel.priceAfterDiscountLabel ?? "")
            }
            .padding(.top)
            .renderedIf(viewModel.hasDiscount)
            Divider()
                .padding()
            Button(Localization.removeProductLabel) {
                viewModel.removeProductIntent()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(Color(.error))
            .overlay {
                VStack(alignment: .leading) {
                    Text("Discounts unavailable")
                        .font(.body)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text("To add a Product Discount, please remove all Coupons from your order")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    Color.black
                        .cornerRadius(4)
                }
                .opacity(1)
                .padding()
                .renderedIf(shouldShowCouponsInfoTooltip)
            }
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

private extension CollapsibleProductRowCard {
    @ViewBuilder var discountRow: some View {
        if viewModel.discount == nil {
            Button(Localization.addDiscountLabel) {
                onAddDiscount()
            }
            .buttonStyle(PlusButtonStyle())
        } else {
            HStack {
                Button(action: {
                    onAddDiscount()
                }, label: {
                    HStack {
                        Text(Localization.discountLabel)
                        Image(uiImage: .pencilImage)
                            .resizable()
                            .frame(width: Layout.iconSize, height: Layout.iconSize)
                    }
                })
                Spacer()
                if let discountLabel = viewModel.discountLabel {
                    Text(minusSign + discountLabel)
                        .foregroundColor(.green)
                }
            }
        }
        Spacer()
            .renderedIf(!viewModel.hasDiscount)
        Button {
            shouldShowCouponsInfoTooltip.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundColor(Color(.wooCommercePurple(.shade60)))
        }
        .renderedIf(!viewModel.hasDiscount)
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
                Image(systemName: "multiply")
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
        static let iconSize: CGFloat = 16
    }

    enum Localization {
        static let priceLabel = NSLocalizedString(
            "Price",
            comment: "Text in the product row card that indicating the price of the product")
        static let removeProductLabel = NSLocalizedString(
            "Remove product from order",
            comment: "Text in the product row card button to remove a product from the current order")
        static let addDiscountLabel = NSLocalizedString(
            "Add discount",
            comment: "Text in the product row card to add a discount to a given product")
        static let discountLabel = NSLocalizedString(
            "Discount",
            comment: "Text in the product row card when a discount has already been added to a product")
        static let priceAfterDiscountLabel = NSLocalizedString(
            "Price after discount",
            comment: "The label that points to the updated price of a product after a discount has been applied")
    }
}

#if DEBUG
struct CollapsibleProductRowCard_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product.swiftUIPreviewSample()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)
        CollapsibleProductRowCard(viewModel: viewModel, onAddDiscount: {})
    }
}
#endif
