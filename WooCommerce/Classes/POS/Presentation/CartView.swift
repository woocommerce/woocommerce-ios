import SwiftUI

struct CartView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    private let viewHelper = CartViewHelper()

    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.colorScheme) var colorScheme

    @State private var offSetPosition: CGFloat = 0.0
    private var coordinateSpace: CoordinateSpace = .named(Constants.scrollViewCoordinateSpaceIdentifier)
    private var shouldApplyHeaderBottomShadow: Bool {
        posModel.cart.isNotEmpty && offSetPosition < 0
    }

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
                                .foregroundColor(Color.posSecondaryText)
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
                            .font(Constants.clearButtonFont)
                            .padding(Constants.clearButtonTextPadding)
                            .foregroundColor(Color.init(uiColor: .wooCommercePurple(.shade60)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.clearButtonCornerRadius)
                                    .stroke(Color.init(uiColor: .wooCommercePurple(.shade60)), lineWidth: Constants.clearButtonBorderWidth)
                            )
                    }
                    .padding(.leading, Constants.itemHorizontalPadding)
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
                        VStack(spacing: 0) {
                            ForEach(posModel.cart, id: \.id) { cartItem in
                                ItemRowView(cartItem: cartItem,
                                            onItemRemoveTapped: posModel.orderStage == .building ? {
                                    posModel.remove(cartItem: cartItem)
                                } : nil)
                                .id(cartItem.id)
                                .transition(.opacity)
                            }
                        }
                        .animation(Constants.cartAnimation, value: posModel.cart.map(\.id))
                        .padding(.bottom, floatingControlAreaSize.height)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: ScrollOffSetPreferenceKey.self,
                                                   value: geometry.frame(in: coordinateSpace).origin.y)
                        })
                        .onPreferenceChange(ScrollOffSetPreferenceKey.self) { position in
                            self.offSetPosition = position
                        }
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

private extension CartView {
    var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.posSecondaryBackground
        default:
            return posModel.cart.isEmpty ? Color.posTertiaryBackground : Color.posSecondaryBackground
        }
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
}

private extension CartView {
    enum Constants {
        static let primaryFont: POSFontStyle = .posTitleEmphasized
        static let secondaryFont: POSFontStyle = .posBodyRegular
        static let itemsFont: POSFontStyle = .posDetailRegular
        static let clearButtonFont: POSFontStyle = .posDetailEmphasized
        static let clearButtonCornerRadius: CGFloat = 4
        static let clearButtonBorderWidth: CGFloat = 2
        static let clearButtonTextPadding = EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24)
        static let itemHorizontalPadding: CGFloat = 8
        static let shoppingBagImageSize: CGFloat = 104
        static let scrollViewCoordinateSpaceIdentifier: String = "CartScrollView"
        static let emptyViewImageTextSpacing: CGFloat = 30 // This should be 40 by designs, but the overlay technique means we have to tweak it
        static let cartHeaderSpacing: CGFloat = 8
        static let backButtonSymbol: String = "chevron.backward"
        static let cartHeaderElementSpacing: CGFloat = 16
        static let cartAnimation: Animation = .spring(duration: 0.2)
        static let checkoutButtonVerticalPadding: CGFloat = 16
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
private extension CartView {
    var checkoutButton: some View {
        Button {
            Task { @MainActor in
                await posModel.checkOut()
            }
        } label: {
            Text(Localization.checkoutButtonTitle)
        }
        .buttonStyle(POSPrimaryButtonStyle())
    }

    @ViewBuilder
    var backAddMoreButton: some View {
        switch posModel.orderStage {
        case .building:
            EmptyView()
        case .finalizing:
            Button {
                posModel.addMoreToCart()
            } label: {
                Image(systemName: Constants.backButtonSymbol)
                    .font(.posBodyEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                    .foregroundColor(.primary)
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

#if DEBUG
#Preview {
    CartView()
}
#endif
