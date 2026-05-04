import SwiftUI
import TipKit
import WooFoundation
import struct Yosemite.POSCustomAmount

struct CartView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posCurrencyProvider) private var currencyProvider
    private let viewHelper = CartViewHelper()

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @State private var offSetPosition: CGFloat = 0.0
    @State private var cartContentHeight: CGFloat = 0.0
    @State private var scrollViewHeight: CGFloat = 0.0
    private var shouldApplyHeaderBottomShadow: Bool {
        posModel.cart.isNotEmpty && offSetPosition < 0
    }

    private var shouldApplyFooterTopShadow: Bool {
        let maxOffset = cartContentHeight - scrollViewHeight
        return posModel.cart.isNotEmpty &&
        cartContentHeight > scrollViewHeight &&
        abs(offSetPosition) < maxOffset
    }

    @State private var headerSize: CGSize = .zero
    @State private var showBarcodeScanningModal: Bool = false
    @State private var showCustomAmountSheet: Bool = false
    @State private var editingCustomAmount: POSCustomAmount?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CartHeaderView(
                    shouldApplyHeaderBottomShadow: shouldApplyHeaderBottomShadow,
                    shouldShowClearCartButton: shouldShowClearCartButton,
                    itemCount: posModel.cart.purchasableItems.count,
                    backgroundColor: backgroundColor,
                    onAddCustomAmountTapped: presentAddCustomAmount
                )
                .zIndex(1)
                .trackSize(size: $headerSize)

                if posModel.cart.isNotEmpty {
                    CartScrollViewContent(
                        offSetPosition: $offSetPosition,
                        cartContentHeight: $cartContentHeight,
                        scrollViewHeight: $scrollViewHeight,
                        onEditCustomAmount: presentEditCustomAmount
                    )
                } else {
                    Spacer()
                }

                if viewHelper.shouldShowCheckout(orderStage: posModel.orderStage, cart: posModel.cart) {
                    checkoutButton
                        .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
                        .padding(.vertical, Constants.checkoutButtonVerticalPadding)
                        .accessibilityAddTraits(.isHeader)
                        .if(shouldApplyFooterTopShadow, transform: { $0.applyEdgeShadow(backgroundColor: backgroundColor, edges: .top) })
                        .zIndex(1)
                }
            }
            .ignoresSafeArea(.posContainerRegionToIgnore, edges: .bottom)
            .posModal(isPresented: $showBarcodeScanningModal) {
                POSBarcodeScannerSetup(isPresented: $showBarcodeScanningModal, analytics: analytics)
            }
            .posFullScreenCover(isPresented: $showCustomAmountSheet) {
                AddCustomAmountView(
                    isPresented: $showCustomAmountSheet,
                    currencySettings: currencyProvider.currencySettings,
                    editing: editingCustomAmount,
                    onSubmit: { customAmount in
                        let mode: WooAnalyticsEvent.PointOfSale.CustomAmountMode = editingCustomAmount != nil ? .edit : .add
                        posModel.upsertCustomAmount(customAmount, mode: mode)
                    }
                )
            }
            .animation(Constants.cartAnimation, value: posModel.cart.isEmpty)
            .frame(maxWidth: .infinity)
            .background(content: {
                if posModel.cart.isEmpty {
                    cartEmptyView
                }
            })
            .background(backgroundColor.ignoresSafeArea(.all))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("pos-cart-view")
        }
    }

    private func presentAddCustomAmount() {
        editingCustomAmount = nil
        showCustomAmountSheet = true
    }

    private func presentEditCustomAmount(_ customAmount: POSCustomAmount) {
        editingCustomAmount = customAmount
        showCustomAmountSheet = true
    }
}

private struct CartHeaderView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posFeatureFlags) private var featureFlags
    private let viewHelper = CartViewHelper()

    let shouldApplyHeaderBottomShadow: Bool
    let shouldShowClearCartButton: Bool
    let itemCount: Int
    let backgroundColor: Color
    let onAddCustomAmountTapped: () -> Void

    private var shouldShowAddCustomAmountButton: Bool {
        viewHelper.shouldShowAddCustomAmountButton(
            featureFlags: featureFlags,
            orderStage: posModel.orderStage)
    }

    private var shouldPreventCartEditing: Bool {
        viewHelper.shouldPreventCartEditing(
            orderState: posModel.orderState,
            paymentState: posModel.paymentState)
    }

    private var backButtonConfiguration: POSPageHeaderBackButtonConfiguration? {
        switch posModel.orderStage {
        case .building:
            return nil
        case .finalizing:
            let state: POSPageHeaderBackButtonConfiguration.State = shouldPreventCartEditing ? .shimmering : .enabled
            return .init(state: state, action: {
                analytics.track(.pointOfSaleBackToCartTapped)
                posModel.addMoreToCart()
            })
        }
    }

    var body: some View {
        POSPageHeaderView(title: Localization.cartTitle,
                          backButtonConfiguration: backButtonConfiguration,
                          trailingContent: {
            HStack(spacing: Constants.cartHeaderElementSpacing) {
                if let itemsInCartLabel = viewHelper.itemsInCartLabel(for: itemCount) {
                    Text(itemsInCartLabel)
                        .font(Constants.itemsFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .foregroundColor(Color.posOnSurfaceVariantLowest)
                }

                if shouldShowAddCustomAmountButton {
                    CartAddCustomAmountButton(onTap: onAddCustomAmountTapped)
                }

                CartClearMenuButton(removeAllItemsFromCart: {
                    posModel.removeAllItemsFromCart()
                })
                .renderedIf(shouldShowClearCartButton)
            }
        })
        .if(shouldApplyHeaderBottomShadow, transform: { $0.applyEdgeShadow(backgroundColor: backgroundColor, edges: .bottom) })
    }

    private enum Localization {
        static let cartTitle = NSLocalizedString(
            "pos.cartView.cartTitle",
            value: "Cart",
            comment: "Title at the header for the Cart view.")
    }
}

private struct ScrollOffSetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // No-op
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // No-op
    }
}

private struct ScrollViewHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // No-op
    }
}

private extension CartView {
    /// iOS 26 NavigationStack introduces container insets that shift the checkout button up.
    static var containerRegionToIgnore: SafeAreaRegions {
        if #available(iOS 26, *) {
            return .container
        } else {
            return []
        }
    }

    var backgroundColor: Color {
        .posSurfaceBright
    }

    var shouldShowClearCartButton: Bool {
        viewHelper.shouldShowClearCartButton(
            cart: posModel.cart,
            orderStage: posModel.orderStage)
    }
}

private extension CartView {
    enum Localization {
        static let barcodeScanningSetup = NSLocalizedString(
            "pos.cartView.cartTitle.barcodeScanningSetup.button",
            value: "Scan barcode",
            comment: "The title of the menu button to start a barcode scanner setup flow."
        )
        static let addItemsToCartOrScanHint = NSLocalizedString(
            "pos.cartView.addItemsToCartOrScanHint",
            value: "Tap on a product to \n add it to the cart, or ",
            comment: "Hint to add products to the Cart when this is empty.")
        static let checkoutButtonTitle = NSLocalizedString(
            "pos.cartView.checkoutButtonTitle",
            value: "Check out",
            comment: "Title for the 'Checkout' button to process the Order.")
    }
}

private enum Constants {
    static let secondaryFont: POSFontStyle = .posBodyMediumRegular()
    static let itemsFont: POSFontStyle = .posBodySmallRegular()
    static let shoppingBagImageSize: CGFloat = 104
    static let scrollViewCoordinateSpaceIdentifier: String = "CartScrollView"
    static let emptyViewImageTextSpacing: CGFloat = POSSpacing.xLarge // This should be 40 by designs, but the overlay technique means we have to tweak it
    static let cartHeaderElementSpacing: CGFloat = POSSpacing.medium
    static let cartAnimation: Animation = .spring(duration: 0.2)
    static let checkoutButtonVerticalPadding: CGFloat = POSPadding.medium
    static let cartItemSpacing: CGFloat = POSSpacing.medium
    static let cartLastItemBottomPadding: CGFloat = POSPadding.large
}

/// View sub-components
///
private extension CartView {
    var checkoutButton: some View {
        Button {
            Task { @MainActor in
                trackCheckoutTapped()
                await posModel.checkOut()
            }
        } label: {
            Text(Localization.checkoutButtonTitle)
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .disabled(CartViewHelper().hasUnresolvedItems(cart: posModel.cart))
        .accessibilityIdentifier("pos-checkout-button")
    }

    var cartEmptyView: some View {
        VStack {
            Spacer(minLength: headerSize.height + Constants.shoppingBagImageSize + Constants.emptyViewImageTextSpacing)
            // By designs, the text should be vertically centred with the image 40px above it.
            // SwiftUI doesn't allow us to absolutely pin a view to the centre then position other views relative to it
            // Instead, we can centre the text, and then put the image in an offset overlay. Offsetting from the top
            // avoids issues when the text size is changed through dynamic type.
            Text(Localization.addItemsToCartOrScanHint)
                .font(Constants.secondaryFont)
                .foregroundColor(Color.posOnSurfaceVariantLowest)
                .multilineTextAlignment(.center)
                .overlay(alignment: .top) {
                    SharedImageAsset.shoppingBags.decorativeImage
                        .resizable()
                        .frame(width: Constants.shoppingBagImageSize, height: Constants.shoppingBagImageSize, alignment: .bottom)
                        .offset(y: -(Constants.shoppingBagImageSize + Constants.emptyViewImageTextSpacing))
                        .aspectRatio(contentMode: .fit)
                }
                Button(action: {
                    analytics.track(.pointOfSaleEmptyCartSetupScannerTapped)
                    showBarcodeScanningModal = true
                }, label: {
                    HStack {
                        Text(Localization.barcodeScanningSetup)
                            .font(Constants.secondaryFont)
                            .foregroundColor(Color.posOnSurfaceVariantLowest)
                        Image(systemName: "barcode.viewfinder")
                    }
                })
            Spacer()
        }
        .background(backgroundColor.ignoresSafeArea(.all))
    }
}

private struct CartAddCustomAmountButton: View {
    static let tip = AddCustomAmountTip()

    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Self.tip.invalidate(reason: .actionPerformed)
            onTap()
        }) {
            Image(systemName: "plus")
                .font(.posButtonSymbolMedium)
                .foregroundStyle(Color.posOnSurface)
                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                .accessibilityLabel(Localization.addCustomAmountAccessibilityLabel)
        }
        .popoverTip(Self.tip, arrowEdge: .top)
        .accessibilityIdentifier("pos-add-custom-amount-header-button")
    }

    enum Localization {
        static let addCustomAmountAccessibilityLabel = NSLocalizedString(
            "pos.cartView.addCustomAmount.header.accessibilityLabel",
            value: "Add custom amount",
            comment: "Accessibility label for the Point of Sale cart header button that opens the add custom amount form.")
    }
}

private struct CartClearMenuButton: View {
    @Environment(\.posAnalytics) private var analytics
    let removeAllItemsFromCart: () -> Void

    var body: some View {
        Menu {
            Button(role: .destructive,
                   action: {
                removeAllItemsFromCart()
                analytics.track(.pointOfSaleClearCartTapped)
            }) {
                Text(Localization.clearButtonTitle)
            }

        } label: {
            Image(systemName: "trash")
                .font(.posButtonSymbolMedium)
                .foregroundStyle(Color.posOnSurface)
                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                .accessibilityLabel(Localization.clearButtonTitle)
        }
    }

    enum Localization {
        static let clearButtonTitle = NSLocalizedString(
            "pos.cartView.clearButtonTitle.1",
            value: "Clear cart",
            comment: "Title for the 'Clear cart' confirmation button to remove all products from the Cart.")
    }
}

private struct CartScrollViewContent: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var offSetPosition: CGFloat
    @Binding var cartContentHeight: CGFloat
    @Binding var scrollViewHeight: CGFloat
    let onEditCustomAmount: (POSCustomAmount) -> Void

    @State private var shouldShowItemImages: Bool = false

    private var coordinateSpace: CoordinateSpace {
        .named(Constants.scrollViewCoordinateSpaceIdentifier)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Constants.cartItemSpacing) {
                    if posModel.cart.customAmounts.isNotEmpty {
                        CustomAmountsCartSection(onEditCustomAmount: onEditCustomAmount)
                    }

                    if posModel.cart.coupons.isNotEmpty {
                        CouponsCartSection(shouldShowItemImages: $shouldShowItemImages)
                    }

                    PurchasableItemsCartSection(shouldShowItemImages: $shouldShowItemImages)
                }
                .padding(.bottom, Constants.cartLastItemBottomPadding)
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: ScrollOffSetPreferenceKey.self,
                                           value: geometry.frame(in: coordinateSpace).origin.y)
                    .preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                    .onAppear {
                        updateItemImageVisibility(cartListWidth: geometry.size.width)
                    }
                    .onChange(of: geometry.size.width) { _, newValue in
                        updateItemImageVisibility(cartListWidth: newValue)
                    }
                    .onChange(of: dynamicTypeSize) { _, newValue in
                        updateItemImageVisibility(dynamicTypeSize: newValue, cartListWidth: geometry.size.width)
                    }
                })
                .onPreferenceChange(ScrollOffSetPreferenceKey.self) { position in
                    offSetPosition = position
                }
                .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                    cartContentHeight = height
                }

                Spacer()
                    .frame(height: floatingControlAreaSize.height)
                    .renderedIf(posModel.orderStage == .finalizing)
            }
            .background {
                GeometryReader() { proxy in
                    Color.clear.preference(key: ScrollViewHeightPreferenceKey.self, value: proxy.size.height)
                }
            }
            .onPreferenceChange(ScrollViewHeightPreferenceKey.self) { height in
                scrollViewHeight = height
            }
            .coordinateSpace(name: Constants.scrollViewCoordinateSpaceIdentifier)
            .onChange(of: posModel.cart.purchasableItems.first?.id) { _, itemToScrollTo in
                if posModel.orderStage == .building {
                    withAnimation {
                        proxy.scrollTo(itemToScrollTo)
                    }
                }
            }
        }
        .animation(Constants.cartAnimation, value: posModel.cart.purchasableItems.map(\.id))
        .animation(Constants.cartAnimation, value: posModel.cart.coupons.map(\.id))
        .animation(Constants.cartAnimation, value: posModel.cart.customAmounts.map(\.id))
        .geometryGroup()
    }


    private func updateItemImageVisibility(dynamicTypeSize: DynamicTypeSize? = nil, cartListWidth: CGFloat) {
        let newVisibility = cartListWidth >= minimumWidthToShowItemImages(with: dynamicTypeSize ?? self.dynamicTypeSize)
        guard newVisibility != shouldShowItemImages else {
            return
        }
        shouldShowItemImages = newVisibility
    }

    private func minimumWidthToShowItemImages(with dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            240
        case .medium:
            260
        case .large:
            270
        case .xLarge:
            280
        case .xxLarge, .xxxLarge:
            300
        case .accessibility1:
            320
        case .accessibility2:
            400
        case .accessibility3, .accessibility4:
            420
        case .accessibility5:
            450
        @unknown default:
            450
        }
    }
}

private struct CustomAmountsCartSection: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics

    let onEditCustomAmount: (POSCustomAmount) -> Void

    var body: some View {
        LazyVStack(spacing: Constants.cartItemSpacing) {
            ForEach(posModel.cart.customAmounts, id: \.id) { customAmount in
                let isInteractive = posModel.orderStage == .building
                CustomAmountRowView(
                    customAmount: customAmount,
                    onEdit: isInteractive ? { onEditCustomAmount(customAmount) } : nil,
                    onRemove: isInteractive ? {
                        analytics.track(
                            event: .PointOfSale.itemRemovedFromCart(
                                sourceView: .cart,
                                itemType: .customAmount
                            )
                        )
                        posModel.removeCustomAmount(id: customAmount.id)
                    } : nil
                )
                .id(customAmount.id)
                .transition(.opacity)
            }
        }
    }
}

private struct CouponsCartSection: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics

    @Binding var shouldShowItemImages: Bool

    private let viewHelper = CartViewHelper()

    var body: some View {
        LazyVStack(spacing: Constants.cartItemSpacing) {
            ForEach(posModel.cart.coupons, id: \.id) { couponItem in
                CouponRowView(
                    couponItem: couponItem,
                    couponRowState: viewHelper.couponRowState(
                        orderStage: posModel.orderStage,
                        orderState: posModel.orderState,
                        couponItem: couponItem
                    ),
                    showImage: $shouldShowItemImages,
                    onItemRemoveTapped: posModel.orderStage == .building ? {
                        analytics.track(
                            event: .PointOfSale.itemRemovedFromCart(
                                sourceView: .cart,
                                itemType: .coupon
                            )
                        )
                        posModel.remove(cartItem: couponItem)
                    } : nil
                )
                .id(couponItem.id)
                .transition(.opacity)
            }
        }
    }
}

private struct PurchasableItemsCartSection: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @Binding var shouldShowItemImages: Bool
    @AccessibilityFocusState private var accessibilityFocusedItem: UUID?

    var body: some View {
        LazyVStack(spacing: Constants.cartItemSpacing) {
            ForEach(posModel.cart.purchasableItems, id: \.id) { cartItem in
                ItemRowView(
                    cartItem: cartItem,
                    showImage: $shouldShowItemImages,
                    onItemRemoveTapped: itemRemoveCallback(for: cartItem),
                    onCancelLoading: cancelLoadingCallback(for: cartItem)
                )
                .id(cartItem.id)
                .transition(.opacity)
                .accessibilityFocused($accessibilityFocusedItem, equals: cartItem.id)
            }
            .onChange(of: posModel.cart.accessibilityFocusedItemID) { _, itemID in
                 if let itemID {
                     Task { @MainActor in
                         accessibilityFocusedItem = itemID
                     }
                 }
             }
        }
    }

    private func itemRemoveCallback(for cartItem: Cart.PurchasableItem) -> (() -> Void)? {
        guard posModel.orderStage == .building else { return nil }

        return {
            analytics.track(
                event: .PointOfSale.itemRemovedFromCart(
                    sourceView: .cart,
                    itemType: .init(cartItem: cartItem),
                    productType: .init(cartItem: cartItem)
                )
            )
            posModel.remove(cartItem: cartItem)
        }
    }

    private func cancelLoadingCallback(for cartItem: Cart.PurchasableItem) -> () -> Void {
        return {
            analytics.track(
                event: .PointOfSale.itemRemovedFromCart(
                    sourceView: .cart,
                    itemType: .loading
                )
            )
            posModel.cancelLoadingItem(id: cartItem.id)
        }
    }
}

private extension CartView {
    func trackCheckoutTapped() {
        let purchasableItems = posModel.cart.purchasableItems.count
        let coupons = posModel.cart.coupons.count
        analytics.track(
            event: .PointOfSale.checkoutTapped(
                purchasableItemsInCart: purchasableItems,
                couponsInCart: coupons
            )
        )
    }
}

#if DEBUG
#Preview {
    CartView()
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Cart with one item") {
    let posModel = POSPreviewHelpers.makePreviewAggregateModel()
    posModel.addToCart(.simpleProduct(.init(id: .init(underlyingType: .product, itemID: 6),
                                            name: "Sample Product",
                                            formattedPrice: "$10.00",
                                            productID: 6,
                                            price: "10",
                                            manageStock: false,
                                            stockQuantity: nil,
                                            stockStatusKey: "")))
    return CartView()
        .environment(posModel)
}
#endif
