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
        itemCount == 1
            ? String(format: Localization.singleItem, itemCount)
            : String(format: Localization.multipleItems, itemCount)
    }

    private enum Localization {
        static let emptyCart = NSLocalizedString(
            "pointOfSale.phone.cartButton.empty",
            value: "Cart",
            comment: "Title shown on the cart button when no items have been added to the POS cart."
        )
        static let singleItem = NSLocalizedString(
            "pointOfSale.phone.cartButton.singleItem",
            value: "%1$d item",
            comment: "Cart button label showing singular item count. %1$d is the number of items."
        )
        static let multipleItems = NSLocalizedString(
            "pointOfSale.phone.cartButton.multipleItems",
            value: "%1$d items",
            comment: "Cart button label showing plural item count. %1$d is the number of items."
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
