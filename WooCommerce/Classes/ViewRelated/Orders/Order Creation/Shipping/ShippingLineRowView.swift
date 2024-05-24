import SwiftUI
import Foundation
import WooFoundation

struct ShippingLineRowView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// View model to drive the view content
    let viewModel: ShippingLineRowViewModel

    var body: some View {
        HStack(alignment: .top, spacing: Layout.contentSpacing) {
            VStack(alignment: .leading) {
                Text(viewModel.shippingTitle)
                    .bodyStyle()
                    .multilineTextAlignment(.leading)
                // Avoids the shipping line name to be truncated when it's long enough
                    .fixedSize(horizontal: false, vertical: true)

                if let shippingMethod = viewModel.shippingMethod {
                    Text(shippingMethod)
                        .subheadlineStyle()
                }
            }

            Spacer()

            Text(viewModel.shippingAmount)
                .bodyStyle()

            Image(systemName: "pencil")
                .resizable()
                .frame(width: Layout.editIconImageSize * scale,
                       height: Layout.editIconImageSize * scale)
                .foregroundColor(Color(.wooCommercePurple(.shade60)))
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(Localization.editButtonAccessibilityLabel)
                .renderedIf(viewModel.editable)
        }
        .padding(Layout.contentPadding)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onEditShippingLine()
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
    ShippingLineRowView(viewModel: ShippingLineRowViewModel(id: 1,
                                                            shippingTitle: "Package 1",
                                                            shippingMethod: "Flat Rate",
                                                            shippingAmount: "$5.00",
                                                            editable: true))
}

#Preview("Not editable") {
    ShippingLineRowView(viewModel: ShippingLineRowViewModel(id: 1,
                                                            shippingTitle: "Package 1",
                                                            shippingMethod: "Flat Rate",
                                                            shippingAmount: "$5.00",
                                                            editable: false))
}
