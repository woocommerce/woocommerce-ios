import SwiftUI

/// The collapsed cart bar shown at the bottom of the Sale tab, above the tab bar.
/// Shows ~1.5 rows of cart items, total, and a checkout button.
/// Tapping expands to the full cart sheet.
struct POSCartPeekView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics

    let onExpandCart: () -> Void
    let onCheckout: () -> Void

    private let viewHelper = CartViewHelper()

    var body: some View {
        filledBar
    }
}

private extension POSCartPeekView {
    var filledBar: some View {
        VStack(spacing: .zero) {
            // Drag handle hint
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: 36, height: 4)
                .padding(.top, POSPadding.small)
                .padding(.bottom, POSPadding.xSmall)

            // Cart header
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
            .padding(.horizontal, POSPadding.small)
            .padding(.bottom, POSPadding.xSmall)

            // Visible item rows (~1.5 rows, clipped with fade)
            VStack(spacing: POSSpacing.xSmall) {
                ForEach(posModel.cart.purchasableItems.prefix(2), id: \.id) { cartItem in
                    ItemRowView(
                        cartItem: cartItem,
                        showImage: .constant(true),
                        onItemRemoveTapped: nil,
                        onCancelLoading: {
                            posModel.cancelLoadingItem(id: cartItem.id)
                        }
                    )
                    .id(cartItem.id)
                    .transition(.opacity)
                }
            }
            .environment(\.dynamicTypeSize, .xSmall)
            .animation(.spring(duration: 0.2), value: posModel.cart.purchasableItems.map(\.id))
            .frame(maxHeight: 80, alignment: .top)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, Color.posSurfaceBright],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 16)
            }

            // Checkout button
            Button {
                onCheckout()
            } label: {
                Text(Localization.checkout)
            }
            .buttonStyle(POSFilledButtonStyle(size: .small))
            .disabled(CartViewHelper().hasUnresolvedItems(cart: posModel.cart))
            .padding(.horizontal, POSPadding.small)
            .padding(.vertical, POSPadding.xSmall)
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.large.value))
        .onTapGesture {
            onExpandCart()
        }
    }
}

private extension POSCartPeekView {
    enum Localization {
        static let cart = NSLocalizedString(
            "pos.phone.cartPeek.title",
            value: "Cart",
            comment: "Title for the cart peek bar in phone POS"
        )
        static let checkout = NSLocalizedString(
            "pos.phone.cartPeek.checkout",
            value: "Check out",
            comment: "Title for the checkout button in the phone POS cart peek"
        )
        static let clearCart = NSLocalizedString(
            "pos.phone.cartPeek.clearCart",
            value: "Clear cart",
            comment: "Button to clear all items from the cart in phone POS"
        )
    }
}
