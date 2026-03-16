import SwiftUI

/// Full cart view shown as a sheet when the user expands the cart peek bar.
struct POSCartSheetView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.dismiss) private var dismiss

    private let viewHelper = CartViewHelper()

    var body: some View {
        NavigationStack {
            VStack(spacing: .zero) {
                cartItemsList
                summaryBar
            }
            .background(Color.posSurfaceBright)
            .navigationTitle(Localization.cart)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if posModel.cart.isNotEmpty {
                        Menu {
                            Button(role: .destructive) {
                                analytics.track(.pointOfSaleClearCartTapped)
                                posModel.removeAllItemsFromCart()
                            } label: {
                                Text(Localization.clearCart)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.posButtonSymbolMedium)
                                .foregroundStyle(Color.posOnSurface)
                        }
                    }
                }
            }
        }
    }
}

private extension POSCartSheetView {
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
                            onItemRemoveTapped: {
                                analytics.track(
                                    event: .PointOfSale.itemRemovedFromCart(
                                        sourceView: .cart,
                                        itemType: .init(cartItem: cartItem),
                                        productType: .init(cartItem: cartItem)
                                    )
                                )
                                posModel.remove(cartItem: cartItem)
                            },
                            onCancelLoading: {
                                posModel.cancelLoadingItem(id: cartItem.id)
                            }
                        )
                        .id(cartItem.id)
                    }
                }
                .padding(.horizontal, POSPadding.medium)
                .padding(.vertical, POSPadding.medium)
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
                dismiss()
            } label: {
                Text(Localization.done)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .padding(.horizontal, POSPadding.medium)
        .padding(.vertical, POSPadding.small)
        .renderedIf(posModel.cart.isNotEmpty)
    }
}

private extension POSCartSheetView {
    enum Localization {
        static let cart = NSLocalizedString(
            "pos.phone.cartSheet.title",
            value: "Cart",
            comment: "Title for the cart sheet in phone POS"
        )
        static let clearCart = NSLocalizedString(
            "pos.phone.cartSheet.clearCart",
            value: "Clear cart",
            comment: "Button to clear all items from the cart in phone POS"
        )
        static let emptyCart = NSLocalizedString(
            "pos.phone.cartSheet.empty",
            value: "Tap a product to add it to the cart",
            comment: "Hint shown when the cart is empty in phone POS"
        )
        static let done = NSLocalizedString(
            "pos.phone.cartSheet.done",
            value: "Done",
            comment: "Button to dismiss the expanded cart sheet in phone POS"
        )
    }
}
