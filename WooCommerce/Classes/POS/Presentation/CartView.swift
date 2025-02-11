import SwiftUI

@available(iOS 17.0, *)
struct CartView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    private let viewHelper = CartViewHelper()

    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @State private var offSetPosition: CGFloat = 0.0
    private var coordinateSpace: CoordinateSpace = .named(Constants.scrollViewCoordinateSpaceIdentifier)
    private var shouldApplyHeaderBottomShadow: Bool {
        posModel.cart.isNotEmpty && offSetPosition < 0
    }

    @State private var shouldShowItemImages: Bool = false

    var body: some View {
        VStack {
            DynamicHStack(spacing: Constants.cartHeaderSpacing) {
                HStack(spacing: Constants.cartHeaderElementSpacing) {
                    backAddMoreButton
                        .disabled(shouldPreventCartEditing)
                        .shimmering(active: shouldPreventCartEditing)

                    HStack {
                        Text(Localization.cartTitle)
                            .font(Constants.primaryFont)
                            .foregroundColor(posModel.cart.isEmpty ? .posSecondaryText : .posPrimaryText)
                            .accessibilityAddTraits(.isHeader)

                        Spacer()

                        if let itemsInCartLabel = viewHelper.itemsInCartLabel(for: posModel.cart.count) {
                            Text(itemsInCartLabel)
                                .font(Constants.itemsFont)
                                .foregroundColor(Color.posOnSurfaceVariantLowest)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }

                HStack {
                    Spacer()
                        .renderedIf(dynamicTypeSize.isAccessibilitySize)

                    Button {
                        posModel.removeAllItemsFromCart()
                    } label: {
                        Text(Localization.clearButtonTitle)
                    }
                    .buttonStyle(POSButtonStyle(variant: .outlined, size: .extraSmall))
                    .renderedIf(shouldShowClearCartButton)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
            .padding(.vertical, POSHeaderLayoutConstants.sectionVerticalPadding)
            .if(shouldApplyHeaderBottomShadow, transform: { $0.applyBottomShadow(backgroundColor: backgroundColor) })

            if posModel.cart.isNotEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: Constants.cartItemSpacing) {
                            ForEach(posModel.cart, id: \.id) { cartItem in
                                ItemRowView(cartItem: cartItem,
                                            showImage: $shouldShowItemImages,
                                            onItemRemoveTapped: posModel.orderStage == .building ? {
                                    ServiceLocator.analytics.track(.pointOfSaleItemRemovedFromCart)
                                    posModel.remove(cartItem: cartItem)
                                } : nil)
                                .id(cartItem.id)
                                .transition(.opacity)
                            }
                        }
                        .animation(Constants.cartAnimation, value: posModel.cart.map(\.id))
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: ScrollOffSetPreferenceKey.self,
                                                   value: geometry.frame(in: coordinateSpace).origin.y)
                            .onAppear {
                                updateItemImageVisibility(cartListWidth: geometry.size.width)
                            }
                            .onChange(of: geometry.size.width) {
                                updateItemImageVisibility(cartListWidth: $0)
                            }
                            .onChange(of: dynamicTypeSize) {
                                updateItemImageVisibility(dynamicTypeSize: $0, cartListWidth: geometry.size.width)
                            }
                        })
                        .onPreferenceChange(ScrollOffSetPreferenceKey.self) { position in
                            self.offSetPosition = position
                        }

                        Spacer()
                            .frame(height: floatingControlAreaSize.height)
                            .renderedIf(posModel.orderStage == .finalizing)
                    }
                    .coordinateSpace(name: Constants.scrollViewCoordinateSpaceIdentifier)
                    .onChange(of: posModel.cart.first?.id) { itemToScrollTo in
                        if posModel.orderStage == .building {
                            withAnimation {
                                proxy.scrollTo(itemToScrollTo)
                            }
                        }
                    }
                }
            }
            Spacer()
            switch posModel.orderStage {
            case .building:
                if posModel.cart.isEmpty {
                    EmptyView()
                } else {
                    checkoutButton
                        .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
                        .padding(.vertical, Constants.checkoutButtonVerticalPadding)
                        .accessibilityAddTraits(.isHeader)
                }
            case .finalizing:
                EmptyView()
            }
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
    }
}

private struct ScrollOffSetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // No-op
    }
}

@available(iOS 17.0, *)
private extension CartView {
    var backgroundColor: Color {
        .posSurfaceBright
    }

    var shouldPreventCartEditing: Bool {
        viewHelper.shouldPreventCartEditing(
            orderState: posModel.orderState,
            paymentState: posModel.paymentState)
    }

    var shouldShowClearCartButton: Bool {
        viewHelper.shouldShowClearCartButton(
            cart: posModel.cart,
            orderStage: posModel.orderStage)
    }

    func updateItemImageVisibility(dynamicTypeSize: DynamicTypeSize? = nil, cartListWidth: CGFloat) {
        let newVisibility = cartListWidth >= minimumWidthToShowItemImages(with: dynamicTypeSize ?? self.dynamicTypeSize)
        guard newVisibility != shouldShowItemImages else {
            return
        }
        shouldShowItemImages = newVisibility
    }

    func minimumWidthToShowItemImages(with dynamicTypeSize: DynamicTypeSize) -> CGFloat {
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

@available(iOS 17.0, *)
private extension CartView {
    enum Constants {
        static let primaryFont: POSFontStyle = .posHeading
        static let secondaryFont: POSFontStyle = .posBodyLargeRegular
        static let itemsFont: POSFontStyle = .posBodySmallRegular
        static let itemHorizontalPadding: CGFloat = 8
        static let shoppingBagImageSize: CGFloat = 104
        static let scrollViewCoordinateSpaceIdentifier: String = "CartScrollView"
        static let emptyViewImageTextSpacing: CGFloat = 30 // This should be 40 by designs, but the overlay technique means we have to tweak it
        static let cartHeaderSpacing: CGFloat = 8
        static let backButtonSymbol: String = "chevron.backward"
        static let cartHeaderElementSpacing: CGFloat = 16
        static let cartAnimation: Animation = .spring(duration: 0.2)
        static let checkoutButtonVerticalPadding: CGFloat = 16
        static let cartItemSpacing: CGFloat = 16
    }

    enum Localization {
        static let cartTitle = NSLocalizedString(
            "pos.cartView.cartTitle",
            value: "Cart",
            comment: "Title at the header for the Cart view.")
        static let clearButtonTitle = NSLocalizedString(
            "pos.cartView.clearButtonTitle",
            value: "Clear",
            comment: "Title for the 'Clear' button to remove all products from the Cart.")
        static let addItemsToCartHint = NSLocalizedString(
            "pos.cartView.addItemsToCartHint",
            value: "Tap on a product to \n add it to the cart",
            comment: "Hint to add products to the Cart when this is empty.")
        static let checkoutButtonTitle = NSLocalizedString(
            "pos.cartView.checkoutButtonTitle",
            value: "Check out",
            comment: "Title for the 'Checkout' button to process the Order.")
    }
}

/// View sub-components
///
@available(iOS 17.0, *)
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
        .buttonStyle(POSButtonStyle(variant: .filled, size: .normal))
    }

    @ViewBuilder
    var backAddMoreButton: some View {
        switch posModel.orderStage {
        case .building:
            EmptyView()
        case .finalizing:
            Button {
                ServiceLocator.analytics.track(.pointOfSaleBackToCartTapped)
                posModel.addMoreToCart()
            } label: {
                Image(systemName: Constants.backButtonSymbol)
                    .font(.posBodyLargeEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                    .foregroundColor(.posOnSurface)
            }
        }
    }

    var cartEmptyView: some View {
        VStack {
            Spacer()
            // By designs, the text should be vertically centred with the image 40px above it.
            // SwiftUI doesn't allow us to absolutely pin a view to the centre then position other views relative to it
            // Instead, we can centre the text, and then put the image in an offset overlay. Offsetting from the top
            // avoids issues when the text size is changed through dynamic type.
            Text(Localization.addItemsToCartHint)
                .font(Constants.secondaryFont)
                .foregroundColor(Color.posTertiaryText)
                .multilineTextAlignment(.center)
                .overlay(alignment: .top) {
                    Image(decorative: PointOfSaleAssets.shoppingBags.imageName)
                        .resizable()
                        .frame(width: Constants.shoppingBagImageSize, height: Constants.shoppingBagImageSize, alignment: .bottom)
                        .offset(y: -(Constants.shoppingBagImageSize + Constants.emptyViewImageTextSpacing))
                        .aspectRatio(contentMode: .fit)
                }
            Spacer()
        }
        .background(backgroundColor.ignoresSafeArea(.all))
    }
}

@available(iOS 17.0, *)
private extension CartView {
    func trackCheckoutTapped() {
        let itemsInCart = posModel.cart.count
        ServiceLocator.analytics.track(event: .PointOfSale.checkoutTapped(itemsInCart))
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    return CartView()
        .environment(posModel)
}

@available(iOS 17.0, *)
#Preview("Cart with one item") {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    posModel.addToCart(.simpleProduct(.init(id: UUID(),
                                            name: "Sample Product",
                                            formattedPrice: "$10.00",
                                            productID: 6,
                                            price: "10")))
    return CartView()
        .environment(posModel)
}
#endif
