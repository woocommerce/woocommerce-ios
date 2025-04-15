import SwiftUI

struct CartRowRemoveButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(Image(systemName: "trash"))
                .font(.posButtonSymbolSmall)
        })
        .accessibilityLabel(Localization.removeFromCartAccessibilityLabel)
        .foregroundColor(Color.posOnSurfaceVariantHighest)
    }

    private enum Localization {
        static let removeFromCartAccessibilityLabel = NSLocalizedString(
            "pointOfSale.item.removeFromCart.button.accessibilityLabel",
            value: "Remove",
            comment: "The accessibility label for the `x` button next to each item in the Point of Sale cart." +
            "The button removes the item. The translation should be short, to make it quick to navigate by voice.")
    }
}
