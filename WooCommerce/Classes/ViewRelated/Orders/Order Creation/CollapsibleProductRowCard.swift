import Yosemite
import SwiftUI

struct CollapsibleProductRowCard: View {
    @ObservedObject var viewModel: ProductRowViewModel
    @State private var isCollapsed: Bool = true

    /// Indicates if the coupons informational tooltip should be shown or not.
    ///
    @State private var shouldShowInfoTooltip: Bool = false

    @ScaledMetric private var scale: CGFloat = 1

    var onAddDiscount: () -> Void

    // Tracks if discount editing should be enabled or disabled. False by default
    //
    var shouldDisableDiscountEditing: Bool = false

    // Tracks if discount should be allowed or disallowed.
    //
    var shouldDisallowDiscounts: Bool = false

    private var shouldShowDividers: Bool {
        !isCollapsed
    }

    private let minusSign: String = NumberFormatter().minusSign

    private func dismissTooltip() {
        if shouldShowInfoTooltip {
            shouldShowInfoTooltip.toggle()
        }
    }

    init(viewModel: ProductRowViewModel, shouldDisableDiscountEditing: Bool, shouldDisallowDiscounts: Bool, onAddDiscount: @escaping () -> Void) {
        self.viewModel = viewModel
        self.shouldDisableDiscountEditing = shouldDisableDiscountEditing
        self.shouldDisallowDiscounts = shouldDisallowDiscounts
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
                            .foregroundColor(.secondary)
                            .renderedIf(isCollapsed)
                        Text(viewModel.skuLabel)
                            .foregroundColor(.secondary)
                            .renderedIf(!isCollapsed)
                        CollapsibleProductCardPriceSummary(viewModel: viewModel)
                    }
                }
            }
            .onTapGesture {
                dismissTooltip()
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

            Button(Localization.configureBundleProduct) {
                viewModel.configure?()
            }
            .buttonStyle(IconButtonStyle(icon: .cogImage))
            .renderedIf(viewModel.isConfigurable)

            Divider()
                .padding()

            Button(Localization.removeProductLabel) {
                viewModel.removeProductIntent()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(Color(.error))
            .overlay {
                TooltipView(toolTipTitle: Localization.discountTooltipTitle,
                            toolTipDescription: Localization.discountTooltipDescription, offset: nil)
                .renderedIf(shouldShowInfoTooltip)
            }
        })
        .onTapGesture {
            dismissTooltip()
        }
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

struct TooltipView: View {

    private let toolTipTitle: String
    private let toolTipDescription: String
    private var offset: CGSize? = nil
    private let safeAreaInsets: EdgeInsets

    init(toolTipTitle: String, toolTipDescription: String, offset: CGSize?, safeAreaInsets: EdgeInsets = .zero) {
        self.toolTipTitle = toolTipTitle
        self.toolTipDescription = toolTipDescription
        self.offset = offset
        self.safeAreaInsets = safeAreaInsets
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: Layout.frameCornerRadius )
                .fill(Color.black)

            TooltipPointerView()
                .fill(Color.black)
                .frame(width: Layout.tooltipPointerSize, height: Layout.tooltipPointerSize)
                .offset(x: Layout.tooltipPointerOffset, y: Layout.tooltipPointerOffset)

            VStack(alignment: .leading) {
                Text(toolTipTitle)
                    .font(.body)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                Text(toolTipDescription)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .offset(offset ?? CGSize(width: 0, height: 0))
        .padding(insets: safeAreaInsets)
    }

    private struct TooltipPointerView: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxY, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }

    private enum Layout {
        static let frameCornerRadius: CGFloat = 4
        static let tooltipPointerSize: CGFloat = 20
        static let tooltipPointerOffset: CGFloat = -10
    }
}

private extension CollapsibleProductRowCard {
    @ViewBuilder var discountRow: some View {
        if !viewModel.hasDiscount || shouldDisallowDiscounts {
            Button(Localization.addDiscountLabel) {
                onAddDiscount()
            }
            .buttonStyle(PlusButtonStyle())
            .disabled(shouldDisallowDiscounts)
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
            // Redacts the discount editing row while product data is reloaded during remote sync.
            // This avoids showing an out-of-date discount while hasn't synched
            .redacted(reason: shouldDisableDiscountEditing ? .placeholder : [] )
        }
        Spacer()
            .renderedIf(!viewModel.hasDiscount)
        Button {
            shouldShowInfoTooltip.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundColor(Color(.wooCommercePurple(.shade60)))
        }
        .renderedIf(!viewModel.hasDiscount || shouldDisallowDiscounts)
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
                    .foregroundColor(.secondary)
                Image(systemName: "multiply")
                    .foregroundColor(.secondary)
                Text(viewModel.priceLabel ?? "-")
                    .foregroundColor(.secondary)
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
        static let discountTooltipTitle = NSLocalizedString(
            "Discounts unavailable",
            comment: "Title text for the product discount row informational tooltip")
        static let discountTooltipDescription = NSLocalizedString(
            "To add a Product Discount, please remove all Coupons from your order",
            comment: "Description text for the product discount row informational tooltip")
        static let configureBundleProduct = NSLocalizedString(
            "Configure",
            comment: "Text in the product row card to configure a bundle product")
    }
}

#if DEBUG
struct CollapsibleProductRowCard_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product.swiftUIPreviewSample()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)
        CollapsibleProductRowCard(viewModel: viewModel,
                                  shouldDisableDiscountEditing: false,
                                  shouldDisallowDiscounts: false,
                                  onAddDiscount: {})
    }
}
#endif
