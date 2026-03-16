import SwiftUI

struct POSCartSheetView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @Binding var selectedDetent: PresentationDetent

    private let viewHelper = CartViewHelper()

    var body: some View {
        VStack(spacing: .zero) {
            cartHeader
            cartItemsList
            summaryBar
        }
        .background(Color.posSurfaceBright)
    }
}

private extension POSCartSheetView {
    var cartHeader: some View {
        HStack {
            Text(Localization.cart)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            if let countLabel = viewHelper.itemsInCartLabel(for: posModel.cart.purchasableItems.count) {
                Text(countLabel)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantLowest)
            }

            Spacer()

            if posModel.cart.isNotEmpty {
                Button(role: .destructive) {
                    analytics.track(.pointOfSaleClearCartTapped)
                    posModel.removeAllItemsFromCart()
                } label: {
                    Image(systemName: "trash")
                        .font(.posButtonSymbolMedium)
                        .foregroundStyle(Color.posOnSurface)
                }
            }
        }
        .padding(.horizontal, POSPadding.medium)
        .padding(.vertical, POSPadding.small)
    }

    @ViewBuilder
    var cartItemsList: some View {
        if posModel.cart.isEmpty {
            emptyCartView
        } else {
            ScrollView {
                LazyVStack(spacing: POSSpacing.medium) {
                    ForEach(posModel.cart.purchasableItems, id: \.id) { cartItem in
                        ItemRowView(
                            cartItem: cartItem,
                            showImage: .constant(true),
                            onItemRemoveTapped: selectedDetent == .large ? {
                                analytics.track(
                                    event: .PointOfSale.itemRemovedFromCart(
                                        sourceView: .cart,
                                        itemType: .init(cartItem: cartItem),
                                        productType: .init(cartItem: cartItem)
                                    )
                                )
                                posModel.remove(cartItem: cartItem)
                            } : nil,
                            onCancelLoading: {
                                posModel.cancelLoadingItem(id: cartItem.id)
                            }
                        )
                        .id(cartItem.id)
                    }
                }
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
    }

    var emptyCartView: some View {
        VStack {
            Spacer()
            Text(Localization.emptyCart)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
            Spacer()
        }
    }

    var summaryBar: some View {
        HStack {
            if case .loaded(let orderTotals) = posModel.orderState {
                Text(orderTotals.orderTotal)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
            } else if posModel.cart.isNotEmpty {
                Text("...")
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurfaceVariantLowest)
            }

            Spacer()

            Button {
                Task { @MainActor in
                    trackCheckoutTapped()
                    await posModel.checkOut()
                }
            } label: {
                Text(Localization.checkout)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .disabled(posModel.cart.isEmpty || CartViewHelper().hasUnresolvedItems(cart: posModel.cart))
        }
        .padding(.horizontal, POSPadding.medium)
        .padding(.vertical, POSPadding.small)
    }

    func trackCheckoutTapped() {
        analytics.track(
            event: .PointOfSale.checkoutTapped(
                purchasableItemsInCart: posModel.cart.purchasableItems.count,
                couponsInCart: posModel.cart.coupons.count
            )
        )
    }
}

private extension POSCartSheetView {
    enum Localization {
        static let cart = NSLocalizedString(
            "pos.phone.cartSheet.title",
            value: "Cart",
            comment: "Title for the cart sheet in phone POS"
        )
        static let checkout = NSLocalizedString(
            "pos.phone.cartSheet.checkout",
            value: "Check out",
            comment: "Title for the checkout button in the phone POS cart sheet"
        )
        static let emptyCart = NSLocalizedString(
            "pos.phone.cartSheet.empty",
            value: "Tap a product to add it to the cart",
            comment: "Hint shown when the cart is empty in phone POS"
        )
    }
}
