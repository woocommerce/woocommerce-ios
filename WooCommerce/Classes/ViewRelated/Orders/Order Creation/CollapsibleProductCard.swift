import Yosemite
import SwiftUI

/// Displays a single collapsible product row or grouped parent and child product rows
struct CollapsibleProductCard: View {
    @ObservedObject var viewModel: ProductRowViewModel

    /// Used for tracking order form events.
    private let flow: WooAnalyticsEvent.Orders.Flow

    /// Handles when "Add Discount" is tapped on the row with the provided `ProductRowViewModel.id`
    private let onAddDiscount: (Int64) -> Void

    /// Tracks if discount editing should be enabled or disabled. False by default
    var shouldDisableDiscountEditing: Bool = false

    /// Tracks if discount should be allowed or disallowed.
    var shouldDisallowDiscounts: Bool = false

    @ScaledMetric private var scale: CGFloat = 1

    init(viewModel: ProductRowViewModel,
         flow: WooAnalyticsEvent.Orders.Flow,
         shouldDisableDiscountEditing: Bool,
         shouldDisallowDiscounts: Bool,
         onAddDiscount: @escaping (_ productRowID: Int64) -> Void) {
        self.viewModel = viewModel
        self.flow = flow
        self.shouldDisableDiscountEditing = shouldDisableDiscountEditing
        self.shouldDisallowDiscounts = shouldDisallowDiscounts
        self.onAddDiscount = onAddDiscount
    }

    var body: some View {
        if viewModel.childProductRows.isEmpty {
            CollapsibleProductRowCard(viewModel: viewModel,
                                      flow: flow,
                                      shouldDisableDiscountEditing: shouldDisableDiscountEditing,
                                      shouldDisallowDiscounts: shouldDisallowDiscounts,
                                      onAddDiscount: onAddDiscount)
            .overlay {
                cardBorder
            }
        } else {
            VStack(spacing: 0) {
                // Parent product
                CollapsibleProductRowCard(viewModel: viewModel,
                                          flow: flow,
                                          shouldDisableDiscountEditing: shouldDisableDiscountEditing,
                                          shouldDisallowDiscounts: shouldDisallowDiscounts,
                                          onAddDiscount: onAddDiscount)
                Divider()
                    .frame(height: Layout.borderLineWidth)
                    .overlay(Color(.separator))

                // Child products
                ForEach(viewModel.childProductRows) { childRow in
                    CollapsibleProductRowCard(viewModel: childRow,
                                              flow: flow,
                                              shouldDisableDiscountEditing: shouldDisableDiscountEditing,
                                              shouldDisallowDiscounts: shouldDisallowDiscounts,
                                              onAddDiscount: onAddDiscount) // TODO: #11250 Update design of child items in product bundle
                    Divider().padding(.horizontal)
                }
            }
            .overlay {
                cardBorder
            }
        }
    }
}

private extension CollapsibleProductCard {
    enum Layout {
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
    }

    var cardBorder: some View {
        RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
            .inset(by: 0.25)
            .stroke(Color(uiColor: .separator), lineWidth: Layout.borderLineWidth)
    }
}

private struct CollapsibleProductRowCard: View {
    @ObservedObject var viewModel: ProductRowViewModel

    /// Used for tracking order form events.
    private let flow: WooAnalyticsEvent.Orders.Flow

    @State private var isCollapsed: Bool = true

    /// Indicates if the coupons informational tooltip should be shown or not.
    ///
    @State private var shouldShowInfoTooltip: Bool = false

    @ScaledMetric private var scale: CGFloat = 1

    private let onAddDiscount: (Int64) -> Void

    // Tracks if discount editing should be enabled or disabled. False by default
    //
    var shouldDisableDiscountEditing: Bool = false

    // Tracks if discount should be allowed or disallowed.
    //
    var shouldDisallowDiscounts: Bool = false

    private var shouldShowDividers: Bool {
        !isCollapsed
    }

    /// Tracks whether the `orderFormBundleProductConfigureCTAShown` event has been tracked to prevent multiple events across view updates.
    @State private var hasTrackedBundleProductConfigureCTAShownEvent: Bool = false

    private let minusSign: String = NumberFormatter().minusSign

    private func dismissTooltip() {
        if shouldShowInfoTooltip {
            shouldShowInfoTooltip.toggle()
        }
    }

    init(viewModel: ProductRowViewModel,
         flow: WooAnalyticsEvent.Orders.Flow,
         shouldDisableDiscountEditing: Bool,
         shouldDisallowDiscounts: Bool,
         onAddDiscount: @escaping (_ productRowID: Int64) -> Void) {
        self.viewModel = viewModel
        self.flow = flow
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
                Text(viewModel.totalPriceAfterDiscountLabel ?? "")
            }
            .padding(.top)
            .renderedIf(viewModel.hasDiscount)

            Divider()
                .padding()

            Group {
                Button(Localization.configureBundleProduct) {
                    viewModel.configure?()
                    ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTATapped(flow: flow, source: .productCard))
                }
                .buttonStyle(IconButtonStyle(icon: .cogImage))

                Divider()
                    .padding()
            }
            .renderedIf(viewModel.isConfigurable)
            .onAppear {
                guard !hasTrackedBundleProductConfigureCTAShownEvent else {
                    return
                }
                ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTAShown(flow: flow, source: .productCard))
                hasTrackedBundleProductConfigureCTAShownEvent = true
            }


            Button(Localization.removeProductLabel) {
                if let removeProductIntent = viewModel.removeProductIntent {
                    removeProductIntent()
                }
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
        .background(Color(.listForeground(modal: false)))
        .overlay {
            RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                .inset(by: 0.25)
                .stroke(Color(uiColor: .black), lineWidth: Layout.borderLineWidth)
                .renderedIf(!isCollapsed)
        }
    }
}

private extension CollapsibleProductRowCard {
    func trackAddDiscountTapped() {
        viewModel.trackAddDiscountTapped()
    }

    func trackEditDiscountTapped() {
        viewModel.trackEditDiscountTapped()
    }
}

private extension CollapsibleProductRowCard {
    @ViewBuilder var discountRow: some View {
        if !viewModel.hasDiscount || shouldDisallowDiscounts {
            Button(Localization.addDiscountLabel) {
                trackAddDiscountTapped()
                onAddDiscount(viewModel.id)
            }
            .buttonStyle(PlusButtonStyle())
            .disabled(shouldDisallowDiscounts)
        } else {
            HStack {
                Button(action: {
                    trackEditDiscountTapped()
                    onAddDiscount(viewModel.id)
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
        .renderedIf(shouldDisallowDiscounts)
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
                Text(viewModel.priceQuantityLine)
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
struct CollapsibleProductCard_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product.swiftUIPreviewSample()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)
        let childViewModels = [ProductRowViewModel(id: 2, product: product, canChangeQuantity: true, hasParentProduct: true),
                               ProductRowViewModel(id: 3, product: product, canChangeQuantity: true, hasParentProduct: true)]
        let parentViewModel = ProductRowViewModel(id: 1, product: product, canChangeQuantity: true, childProductRows: childViewModels)
        VStack {
            CollapsibleProductCard(viewModel: viewModel,
                                      flow: .creation,
                                      shouldDisableDiscountEditing: false,
                                      shouldDisallowDiscounts: false,
                                      onAddDiscount: { _ in })
            CollapsibleProductCard(viewModel: parentViewModel,
                                      flow: .creation,
                                      shouldDisableDiscountEditing: false,
                                      shouldDisallowDiscounts: false,
                                      onAddDiscount: { _ in })
        }
        .padding()
    }
}
#endif