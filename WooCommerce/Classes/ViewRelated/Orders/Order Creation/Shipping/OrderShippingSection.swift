import SwiftUI

struct OrderShippingSection: View {
    /// Use case to add, edit, or remove shipping lines
    @ObservedObject var useCase: EditableOrderShippingUseCase

    @State private var showAddShippingLine: Bool = false

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
                    addShippingLine()
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
        .sheet(isPresented: $showAddShippingLine, content: {
            ShippingLineSelectionDetails(viewModel: useCase.addShippingLineViewModel())
        })
        .sheet(item: $useCase.selectedShippingLine, content: { selectedShippingLine in
            ShippingLineSelectionDetails(viewModel: selectedShippingLine)
        })
    }
}

private extension OrderShippingSection {
    func addShippingLine() {
        showAddShippingLine = true
        // TODO-12584: Track that add shipping has been tapped
    }
}

private extension OrderShippingSection {
    enum Localization {
        static let shipping = NSLocalizedString("orderForm.shipping",
                                                value: "Shipping",
                                                comment: "Heading for the section that shows the Shipping Lines when creating or editing an order")
    }
}
