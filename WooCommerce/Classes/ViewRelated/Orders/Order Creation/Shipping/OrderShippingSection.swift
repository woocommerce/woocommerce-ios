import SwiftUI

struct OrderShippingSection: View {
    /// View model to add, edit, or remove shipping lines
    @ObservedObject var viewModel: EditableOrderShippingLineViewModel

    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack {
            HStack {
                Text(Localization.shipping)
                    .accessibilityAddTraits(.isHeader)
                    .headlineStyle()

                Spacer()

                Image(uiImage: .lockImage)
                    .foregroundColor(Color(.primary))
                    .renderedIf(viewModel.shouldShowNonEditableIndicators)

                Button(action: {
                    viewModel.addShippingLine()
                }) {
                    Image(uiImage: .plusImage)
                }
                .scaledToFit()
                .renderedIf(!viewModel.shouldShowNonEditableIndicators)
            }

            ForEach(viewModel.shippingLineRows) { shippingLineRow in
                ShippingLineRowView(viewModel: shippingLineRow)
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .padding()
        .background(Color(.listForeground(modal: true)))
        .addingTopAndBottomDividers()
        .sheet(item: $viewModel.shippingLineDetails, content: { viewModel in
            ShippingLineSelectionDetails(viewModel: viewModel)
        })
    }
}

private extension OrderShippingSection {
    enum Localization {
        static let shipping = NSLocalizedString("orderForm.shipping",
                                                value: "Shipping",
                                                comment: "Heading for the section that shows the Shipping Lines when creating or editing an order")
    }
}
