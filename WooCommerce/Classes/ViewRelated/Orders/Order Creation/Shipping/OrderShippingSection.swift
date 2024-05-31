import SwiftUI

struct OrderShippingSection: View {
    /// Use case to add, edit, or remove shipping lines
    @ObservedObject var useCase: EditableOrderShippingUseCase

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
                    .renderedIf(useCase.shouldShowNonEditableIndicators)

                Button(action: {
                    useCase.addShippingLine()
                }) {
                    Image(uiImage: .plusImage)
                }
                .scaledToFit()
                .renderedIf(!useCase.shouldShowNonEditableIndicators)
            }

            ForEach(useCase.shippingLineRows) { shippingLineRow in
                ShippingLineRowView(viewModel: shippingLineRow)
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .padding()
        .background(Color(.listForeground(modal: true)))
        .addingTopAndBottomDividers()
        .sheet(item: $useCase.shippingLineDetails, content: { viewModel in
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
