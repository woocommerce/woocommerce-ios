import SwiftUI

struct CartRowEditButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Text(Image(systemName: "pencil"))
                .font(.posButtonSymbolSmall)
        })
        .accessibilityLabel(Localization.editAccessibilityLabel)
        .foregroundColor(Color.posOnSurfaceVariantHighest)
    }

    private enum Localization {
        static let editAccessibilityLabel = NSLocalizedString(
            "pointOfSale.item.edit.button.accessibilityLabel",
            value: "Edit",
            comment: "The accessibility label for the pencil button next to a custom amount in the Point of Sale cart. " +
            "The button opens the edit form. The translation should be short, to make it quick to navigate by voice.")
    }
}
