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
        if posModel.cart.isEmpty {
            emptyBar
        } else {
            filledBar
        }
    }
}

private extension POSCartPeekView {
    var emptyBar: some View {
        HStack {
            Text(Localization.emptyCart)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
            Spacer()
        }
        .padding(.horizontal, POSPadding.medium)
        .padding(.vertical, POSPadding.medium)
        .background(Color.posSurfaceBright)
    }

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
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.bottom, POSPadding.xSmall)

            // Visible item rows (~1.5 rows, clipped)
            VStack(spacing: POSSpacing.small) {
                ForEach(posModel.cart.purchasableItems.prefix(2), id: \.id) { cartItem in
                    HStack {
                        Text(cartItem.title)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(Color.posOnSurface)
                            .lineLimit(1)

                        if cartItem.quantity > 1 {
                            Text("×\(cartItem.quantity)")
                                .font(.posBodySmallRegular())
                                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                        }

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, POSPadding.medium)
            .frame(maxHeight: 52, alignment: .top)
            .clipped()

            // Fade hint if more items
            if posModel.cart.purchasableItems.count > 2 {
                LinearGradient(colors: [.clear, Color.posSurfaceBright],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 8)
            }

            // Summary bar
            HStack {
                if case .loaded(let orderTotals) = posModel.orderState {
                    Text(orderTotals.orderTotal)
                        .font(.posHeadingBold)
                        .foregroundStyle(Color.posOnSurface)
                } else {
                    Text("...")
                        .font(.posHeadingBold)
                        .foregroundStyle(Color.posOnSurfaceVariantLowest)
                }

                Spacer()

                Button {
                    onCheckout()
                } label: {
                    Text(Localization.checkout)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(CartViewHelper().hasUnresolvedItems(cart: posModel.cart))
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.vertical, POSPadding.small)
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
        static let emptyCart = NSLocalizedString(
            "pos.phone.cartPeek.empty",
            value: "Cart is empty",
            comment: "Text shown when the cart is empty in the phone POS cart peek bar"
        )
    }
}
