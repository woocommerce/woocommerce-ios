import SwiftUI

/// Collapsible section for all items to ship with the Woo Shipping extension.
struct WooShippingItems: View {
    /// Label for the total number of items
    let itemsCountLabel: String

    /// Label for the total item details
    let itemsDetailLabel: String

    /// View models for items to ship
    let items: [WooShippingItemRowViewModel]

    /// Whether the item list is collapsed
    @State private var isCollapsed: Bool = true

    var body: some View {
        CollapsibleView(isCollapsed: $isCollapsed,
                        shouldShowDividers: false,
                        backgroundColor: .clear,
                        label: {
            AdaptiveStack {
                Text(itemsCountLabel)
                    .headlineStyle()
                Spacer()
                Text(itemsDetailLabel)
                    .foregroundStyle(Color(.textSubtle))
            }
        },
                        content: {
            VStack {
                ForEach(items) { item in
                    WooShippingItemRow(viewModel: item)
                        .padding()
                        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderWidth)
                }
            }
        })
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .if(isCollapsed) { view in
            view
                .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderWidth)
        }
    }
}

private extension WooShippingItems {
    enum Layout {
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
    }
}

#Preview {
    WooShippingItems(itemsCountLabel: "6 items",
                     itemsDetailLabel: "825g  ·  $135.00",
                     items: [WooShippingItemRowViewModel(imageUrl: nil,
                                                         quantityLabel: "3",
                                                         name: "Little Nap Brazil 250g",
                                                         detailsLabel: "15×10×8cm • Espresso",
                                                         weightLabel: "275g",
                                                         priceLabel: "$60.00"),
                             WooShippingItemRowViewModel(imageUrl: nil,
                                                         quantityLabel: "3",
                                                         name: "Little Nap Brazil 250g",
                                                         detailsLabel: "15×10×8cm • Espresso",
                                                         weightLabel: "275g",
                                                         priceLabel: "$60.00")])
}
