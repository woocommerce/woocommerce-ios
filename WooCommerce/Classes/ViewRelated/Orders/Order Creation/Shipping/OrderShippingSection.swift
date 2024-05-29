import SwiftUI

struct OrderShippingSection: View {
    /// View model to drive the view content
    @ObservedObject var viewModel: EditableOrderViewModel

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
                    .renderedIf(viewModel.shouldShowNonEditableIndicators)

                Button(action: {
                    addShippingLine()
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
        .sheet(isPresented: $showAddShippingLine, content: {
            ShippingLineSelectionDetails(viewModel: viewModel.addShippingLineViewModel())
        })
        .sheet(item: $viewModel.selectedShippingLine, content: { selectedShippingLine in
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
