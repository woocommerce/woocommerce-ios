import SwiftUI
import Foundation
import WooFoundation

struct ShippingLineRowView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// Title for the shipping line
    let shippingTitle: String

    /// Name of the shipping method for the shipping line
    let shippingMethod: String?

    /// Amount for the shipping line
    let shippingAmount: String

    /// Whether the row can be edited
    let editable: Bool

    /// Closure to be invoked when the shipping line is edited
    let onEditShippingLine: () -> Void = {} // TODO-12581: Support editing shipping lines

    var body: some View {
        HStack(alignment: .top, spacing: Layout.contentSpacing) {
            VStack(alignment: .leading) {
                Text(shippingTitle)
                    .bodyStyle()
                    .multilineTextAlignment(.leading)
                // Avoids the shipping line name to be truncated when it's long enough
                    .fixedSize(horizontal: false, vertical: true)

                if let shippingMethod {
                    Text(shippingMethod)
                        .subheadlineStyle()
                }
            }

            Spacer()

            Text(shippingAmount)
                .bodyStyle()

            Image(systemName: "pencil")
                .resizable()
                .frame(width: Layout.editIconImageSize * scale,
                       height: Layout.editIconImageSize * scale)
                .foregroundColor(Color(.wooCommercePurple(.shade60)))
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(Localization.editButtonAccessibilityLabel)
                .renderedIf(editable)
        }
        .padding(Layout.contentPadding)
        .contentShape(Rectangle())
        .onTapGesture {
            onEditShippingLine()
        }
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.borderLineWidth)
        }
    }
}

extension ShippingLineRowView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let borderLineWidth: CGFloat = 0.5
        static let editIconImageSize: CGFloat = 24
    }

    enum Localization {
        static let editButtonAccessibilityLabel = NSLocalizedString(
            "shippingLine.edit.button.accessibilityLabel",
            value: "Edit shipping",
            comment: "Accessibility title for the edit button on a shipping line row.")
    }
}

#Preview("Editable") {
    ShippingLineRowView(shippingTitle: "Package 1", shippingMethod: "Flat Rate", shippingAmount: "$5.00", editable: true)
}

#Preview("Not editable") {
    ShippingLineRowView(shippingTitle: "Package 1", shippingMethod: "Flat Rate", shippingAmount: "$5.00", editable: false)
}
