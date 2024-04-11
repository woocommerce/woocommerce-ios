import Yosemite
import SwiftUI

/// Displays a single collapsible product row or grouped parent and child product rows
struct CollapsibleProductCard: View {
    private let viewModel: CollapsibleProductCardViewModel

    /// Used for tracking order form events.
    private let flow: WooAnalyticsEvent.Orders.Flow

    /// Handles when "Add Discount" is tapped on the row with the provided `ProductRowViewModel.id`
    private let onAddDiscount: (Int64) -> Void

    /// Tracks if discount editing should be enabled or disabled. False by default
    var shouldDisableDiscountEditing: Bool = false

    /// Tracks if discount should be allowed or disallowed.
    var shouldDisallowDiscounts: Bool = false

    @ScaledMetric private var scale: CGFloat = 1

    init(viewModel: CollapsibleProductCardViewModel,
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
            CollapsibleProductRowCard(viewModel: viewModel.productRow,
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
                CollapsibleProductRowCard(viewModel: viewModel.productRow,
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
                                              onAddDiscount: onAddDiscount)
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
    private let viewModel: CollapsibleProductRowCardViewModel

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

    /// Tracks whether the `orderFormBundleProductConfigureCTAShown` event has been tracked to prevent multiple events across view updates.
    @State private var hasTrackedBundleProductConfigureCTAShownEvent: Bool = false

    private let minusSign: String = NumberFormatter().minusSign

    private func dismissTooltip() {
        if shouldShowInfoTooltip {
            shouldShowInfoTooltip = false
        }
    }

    init(viewModel: CollapsibleProductRowCardViewModel,
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
                        shouldShowDividers: false,
                        hasSubtleChevron: viewModel.hasParentProduct,
                        label: {
            VStack {
                HStack(alignment: .center, spacing: Layout.padding) {
                    ProductImageThumbnail(productImageURL: viewModel.imageURL,
                                          productImageSize: viewModel.hasParentProduct ?
                                          Layout.childProductImageSize : Layout.parentProductImageSize,
                                          scale: scale,
                                          productImageCornerRadius: Layout.productImageCornerRadius,
                                          foregroundColor: Color(UIColor.listSmallIcon))
                    .padding(.leading, viewModel.hasParentProduct ? Layout.childLeadingPadding : 0)
                    VStack(alignment: .leading) {
                        Text(viewModel.name)
                            .font(viewModel.hasParentProduct ? .subheadline : .none)
                            .foregroundColor(Color(.text))
                        Text(viewModel.productDetailsLabel)
                            .font(.subheadline)
                            .foregroundColor(isCollapsed ? Color(.textSubtle) : Color(.text))
                        Text(viewModel.subscriptionConditionsDetailsLabel)
                            .subheadlineStyle()
                            .renderedIf(viewModel.shouldShowProductSubscriptionsDetails && isCollapsed)
                        HStack {
                            Text(viewModel.subscriptionBillingDetailsLabel)
                                .font(.subheadline)
                                .foregroundColor(Color(.text))
                                .renderedIf(viewModel.shouldShowProductSubscriptionsDetails && isCollapsed)
                            Spacer()
                            Text(viewModel.subscriptionPrice)
                                .font(.subheadline)
                                .foregroundColor(Color(.text))
                                .renderedIf(viewModel.shouldShowProductSubscriptionsDetails && isCollapsed)
                        }
                        Text(viewModel.skuLabel)
                            .font(.subheadline)
                            .foregroundColor(Color(.text))
                            .renderedIf(!isCollapsed)
                        CollapsibleProductCardPriceSummary(viewModel: viewModel.priceSummaryViewModel)
                            .font(.subheadline)
                            .renderedIf(!viewModel.shouldShowProductSubscriptionsDetails && isCollapsed)
                    }
                }
            }
            .onTapGesture {
                dismissTooltip()
            }
        }, content: {
            VStack(spacing: 16.0) {
                Divider()

                HStack {
                    Text(Localization.orderCountLabel)
                        .subheadlineStyle()
                    Spacer()
                    ProductStepper(viewModel: viewModel.stepperViewModel)
                }
                .renderedIf(!viewModel.isReadOnly)

                HStack {
                    Text(Localization.priceLabel)
                        .subheadlineStyle()
                    Spacer()
                    CollapsibleProductCardPriceSummary(viewModel: viewModel.priceSummaryViewModel)
                }
                .frame(minHeight: Layout.rowMinHeight)

                subscriptionDetailsSection

                Divider()

                discountRow
                .frame(minHeight: Layout.rowMinHeight)
                .renderedIf(!viewModel.isReadOnly)

                HStack {
                    Text(Localization.priceAfterDiscountLabel)
                    Spacer()
                    Text(viewModel.totalPriceAfterDiscountLabel ?? "")
                }
                .frame(minHeight: Layout.rowMinHeight)
                .renderedIf(viewModel.hasDiscount && !viewModel.isReadOnly)

                Button(Localization.configureBundleProduct) {
                    viewModel.configure?()
                    ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTATapped(flow: flow, source: .productCard))
                }
                .buttonStyle(IconButtonStyle(icon: .cogImage))
                .frame(minHeight: Layout.rowMinHeight)
                .renderedIf(viewModel.isConfigurable)
                .onAppear {
                    guard !hasTrackedBundleProductConfigureCTAShownEvent else {
                        return
                    }
                    ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTAShown(flow: flow, source: .productCard))
                    hasTrackedBundleProductConfigureCTAShownEvent = true
                }

                if !viewModel.isReadOnly,
                   let removeProductIntent = viewModel.stepperViewModel.removeProductIntent {
                    Button {
                        removeProductIntent()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: Layout.deleteIconSize))
                            Text(Localization.removeProductLabel)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Color(.error))
                    }
                    .frame(minHeight: Layout.rowMinHeight)
                    .overlay {
                        TooltipView(toolTipTitle: Localization.discountTooltipTitle,
                                    toolTipDescription: Localization.discountTooltipDescription, offset: nil)
                        .renderedIf(shouldShowInfoTooltip)
                    }
                }
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
                .stroke(Color(uiColor: .text), lineWidth: Layout.borderLineWidth)
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
    // Subscription details section. Renders all elements for a Subscription-type product
    @ViewBuilder var subscriptionDetailsSection: some View {
        VStack {
            HStack {
                Text(Localization.Subscription.intervalLabel)
                    .subheadlineStyle()
                Spacer()
                Text(viewModel.subscriptionBillingDetailsLabel)
                    .font(.subheadline)
                    .foregroundColor(Color(.text))
            }

            if let freeTrial = viewModel.subscriptionConditionsFreeTrialLabel {
                HStack {
                    Text(Localization.Subscription.freeTrialLabel)
                        .subheadlineStyle()
                    Spacer()
                    Text(freeTrial)
                        .font(.subheadline)
                        .foregroundColor(Color(.text))
                }
            }

            if let signupFee = viewModel.subscriptionConditionsSignupFee {
                HStack {
                    Text(Localization.Subscription.signUpFeeLabel)
                        .subheadlineStyle()
                    Spacer()
                    Text(signupFee)
                        .font(.subheadline)
                        .foregroundColor(Color(.text))
                }
            }
        }
    }

    @ViewBuilder var discountRow: some View {
        HStack {
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
            Group {
                Spacer()
                Button {
                    shouldShowInfoTooltip.toggle()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(Color(.wooCommercePurple(.shade60)))
                }
            }
            .renderedIf(shouldDisallowDiscounts)
        }
    }
}

private extension CollapsibleProductRowCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let childLeadingPadding: CGFloat = 16.0
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
        static let parentProductImageSize: CGFloat = 56.0
        static let childProductImageSize: CGFloat = 40.0
        static let productImageCornerRadius: CGFloat = 4.0
        static let iconSize: CGFloat = 16
        static let deleteIconSize: CGFloat = 24.0
        static let rowMinHeight: CGFloat = 40.0
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
        static let orderCountLabel = NSLocalizedString(
            "Order Count",
            comment: "Text in the product row card that indicates the product quantity in an order")
        enum Subscription {
            static let intervalLabel = NSLocalizedString(
                "CollapsibleProductRowCard.text.interval",
                value: "Interval",
                comment: "The label points to the charge interval for product subscriptions")
            static let freeTrialLabel = NSLocalizedString(
                "CollapsibleProductRowCard.text.freetrial",
                value: "Free trial",
                comment: "The label points to the free trial conditions for product subscriptions")
            static let signUpFeeLabel = NSLocalizedString(
                "CollapsibleProductRowCard.text.signupfee",
                value: "Signup fee",
                comment: "The label points to the sign up fee conditions for product subscriptions")
        }
    }
}

#if DEBUG
struct CollapsibleProductCard_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product.swiftUIPreviewSample()
        let rowViewModel = CollapsibleProductRowCardViewModel(id: 1,
                                                              productOrVariationID: product.productID,
                                                              hasParentProduct: false,
                                                              isReadOnly: false,
                                                              imageURL: product.imageURL,
                                                              name: product.name,
                                                              sku: product.sku,
                                                              price: product.price,
                                                              productTypeDescription: product.productType.description,
                                                              attributes: [],
                                                              stockStatus: product.productStockStatus,
                                                              stockQuantity: product.stockQuantity,
                                                              manageStock: product.manageStock,
                                                              stepperViewModel: .init(quantity: 1,
                                                                                      name: "",
                                                                                      quantityUpdatedCallback: { _ in }))
        let viewModel = CollapsibleProductCardViewModel(productRow: rowViewModel, childProductRows: [])

        let readOnlyRowViewModel = CollapsibleProductRowCardViewModel(id: 2,
                                                                      productOrVariationID: product.productID,
                                                                      hasParentProduct: false,
                                                                      isReadOnly: true,
                                                                      imageURL: product.imageURL,
                                                                      name: product.name,
                                                                      sku: product.sku,
                                                                      price: product.price,
                                                                      productTypeDescription: product.productType.description,
                                                                      attributes: [],
                                                                      stockStatus: product.productStockStatus,
                                                                      stockQuantity: product.stockQuantity,
                                                                      manageStock: product.manageStock,
                                                                      stepperViewModel: .init(quantity: 1,
                                                                                      name: "",
                                                                                      quantityUpdatedCallback: { _ in }))
        let readOnlyViewModel = CollapsibleProductCardViewModel(productRow: readOnlyRowViewModel, childProductRows: [])

        let childViewModels = [ProductRowViewModel(id: 2, product: product),
                               ProductRowViewModel(id: 3, product: product)]
            .map {
                CollapsibleProductRowCardViewModel(id: $0.id,
                                                   productOrVariationID: product.productID,
                                                   hasParentProduct: true,
                                                   isReadOnly: false,
                                                   imageURL: product.imageURL,
                                                   name: product.name,
                                                   sku: product.sku,
                                                   price: product.price,
                                                   productTypeDescription: product.productType.description,
                                                   attributes: [],
                                                   stockStatus: product.productStockStatus,
                                                   stockQuantity: product.stockQuantity,
                                                   manageStock: product.manageStock,
                                                   stepperViewModel: .init(quantity: 1,
                                                                           name: "",
                                                                           quantityUpdatedCallback: { _ in }))
            }
        let bundleParentRowViewModel = CollapsibleProductRowCardViewModel(id: 4,
                                                                          productOrVariationID: product.productID,
                                                                          hasParentProduct: false,
                                                                          isReadOnly: false,
                                                                          isConfigurable: true,
                                                                          imageURL: product.imageURL,
                                                                          name: product.name,
                                                                          sku: product.sku,
                                                                          price: product.price,
                                                                          productTypeDescription: product.productType.description,
                                                                          attributes: [],
                                                                          stockStatus: product.productStockStatus,
                                                                          stockQuantity: product.stockQuantity,
                                                                          manageStock: product.manageStock,
                                                                          stepperViewModel: .init(quantity: 1,
                                                                                                  name: "",
                                                                                                  quantityUpdatedCallback: { _ in }),
                                                                          configure: {})
        let bundleParentViewModel = CollapsibleProductCardViewModel(productRow: bundleParentRowViewModel,
                                                                    childProductRows: childViewModels)
        VStack {
            CollapsibleProductCard(viewModel: viewModel,
                                      flow: .creation,
                                      shouldDisableDiscountEditing: false,
                                      shouldDisallowDiscounts: false,
                                      onAddDiscount: { _ in })
            CollapsibleProductCard(viewModel: readOnlyViewModel,
                                   flow: .creation,
                                   shouldDisableDiscountEditing: false,
                                   shouldDisallowDiscounts: false,
                                   onAddDiscount: { _ in })
            CollapsibleProductCard(viewModel: bundleParentViewModel,
                                      flow: .creation,
                                      shouldDisableDiscountEditing: false,
                                      shouldDisallowDiscounts: false,
                                      onAddDiscount: { _ in })
        }
        .padding()
    }
}
#endif
