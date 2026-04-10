import SwiftUI

/// Collapsible section for all items to ship with the Woo Shipping extension.
struct WooShippingItems: View {
    /// Label for the total number of items
    let itemsCountLabel: String

    /// Label for the total item details
    let itemsDetailLabel: String

    /// View models for items to ship
    let items: [WooShippingItemRowViewModel]

    /// Summary header accessibility label
    let itemsSummaryAccessibilityValue: String

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
            .padding(.vertical, Layout.textContainerAdditionalVerticalPadding)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Localization.collapsibleHeaderAccessibilityLabel)
            .accessibilityValue(itemsSummaryAccessibilityValue)
            .accessibilityHint(isCollapsed ? Localization.expandHint : Localization.collapseHint)
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
        .padding(.vertical, Layout.verticalPadding)
        .frame(maxWidth: .infinity, alignment: .center)
        .if(isCollapsed) { view in
            view
                .roundedBorder(
                    cornerRadius: Layout.borderCornerRadius,
                    lineColor: Color(.separator),
                    lineWidth: Layout.borderWidth)
                .accessibilityElement(children: .combine)
        }
    }
}

private extension WooShippingItems {
    enum Layout {
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5

        /// Total vertical padding between content and outer border
        static let verticalPadding: CGFloat = 8

        static let textContainerAdditionalVerticalPadding: CGFloat = 2
    }

    private enum Localization {
        static let expandHint = NSLocalizedString(
            "shipping-labels.packages.items.expand.accessibility-hint",
            value: "Double-tap to show all items",
            comment: "Accessibility hint to expand the product items section"
        )
        static let collapseHint = NSLocalizedString(
            "shipping-labels.packages.items.collapse.accessibility-hint",
            value: "Double-tap to hide all items",
            comment: "Accessibility hint to collapse the product items section"
        )
        static let collapsibleHeaderAccessibilityLabel = NSLocalizedString(
            "shipping-labels.packages.items.header.accessibilityLabel",
            value: "Products section",
            comment: "Accessibility label for collapsible products section"
        )
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
                                                         priceLabel: "$60.00")],
                     itemsSummaryAccessibilityValue: "6 items with a total weight of 825g" +
                     " and a total price of $135.00"
    )
}
