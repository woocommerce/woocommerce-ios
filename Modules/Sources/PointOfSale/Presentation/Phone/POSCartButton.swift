import SwiftUI

struct POSCartButton: View {
    let itemCount: Int
    let action: () -> Void

    private var isEmpty: Bool { itemCount == 0 }

    var body: some View {
        Button(action: action) {
            HStack(spacing: POSSpacing.small) {
                Image(systemName: "cart.fill")
                    .font(.posBodyMediumBold)

                if isEmpty {
                    Text(Localization.emptyCart)
                        .font(.posBodyMediumBold)
                } else {
                    Text(cartLabel)
                        .font(.posBodyMediumBold)
                }
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.vertical, POSPadding.medium)
            .frame(maxWidth: .infinity)
            .background(isEmpty ? Color.posDisabledContainer : Color.posPrimaryContainer)
            .foregroundStyle(isEmpty ? Color.posOnDisabledContainer : Color.posOnPrimaryContainer)
            .cornerRadius(POSCornerRadiusStyle.medium.value)
        }
        .disabled(isEmpty)
        .padding(.horizontal, POSPadding.medium)
        .padding(.bottom, POSPadding.small)
        .animation(.spring(duration: 0.3), value: itemCount)
    }

    private var cartLabel: String {
        CartViewHelper().itemsInCartLabel(for: itemCount) ?? Localization.emptyCart
    }

    private enum Localization {
        static let emptyCart = NSLocalizedString(
            "pointOfSale.phone.cartButton.empty",
            value: "Cart",
            comment: "Title shown on the cart button when no items have been added to the POS cart."
        )
    }
}

#if DEBUG
#Preview("Empty") {
    POSCartButton(itemCount: 0, action: {})
        .environment(\.posLayoutScale, .phone)
}

#Preview("With items") {
    POSCartButton(itemCount: 3, action: {})
        .environment(\.posLayoutScale, .phone)
}
#endif
