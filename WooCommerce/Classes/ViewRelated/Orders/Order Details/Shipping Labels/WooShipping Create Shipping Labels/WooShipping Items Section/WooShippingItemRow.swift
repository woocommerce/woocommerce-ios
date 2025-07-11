import SwiftUI

/// Row for an item to ship with the Woo Shipping extension.
struct WooShippingItemRow: View {
    /// URL for item image
    let imageUrl: URL?

    /// Label for item quantity
    let quantityLabel: String

    /// Item name
    let name: String

    /// Label for item details
    let detailsLabel: String

    /// Label for item weight
    let weightLabel: String

    /// Label for item price
    let priceLabel: String

    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        AdaptiveStack(spacing: Layout.horizontalSpacing) {
            ProductImageThumbnail(productImageURL: imageUrl,
                                  productImageSize: Layout.imageSize,
                                  scale: scale,
                                  productImageCornerRadius: Layout.imageCornerRadius,
                                  foregroundColor: Color(UIColor.listSmallIcon))
            .overlay(alignment: .topTrailing) {
                BadgeView(text: quantityLabel,
                          customizations: .init(textColor: .white, backgroundColor: .black),
                          backgroundShape: badgeStyle)
                .offset(x: Layout.badgeOffset, y: -Layout.badgeOffset)
            }
            VStack(alignment: .leading) {
                Text(name)
                    .bodyStyle()
                Text(detailsLabel)
                    .subheadlineStyle()
                AdaptiveStack(verticalAlignment: .lastTextBaseline) {
                    Text(weightLabel)
                        .subheadlineStyle()
                    Spacer()
                    Text(priceLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color(.text))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(accessibilityValue)
    }
}

/// Custom accessibility
private extension WooShippingItemRow {
    var accessibilityValue: String {
        /// Covers item name and quantity if plural
        let quantifiedItemFormattedString: String
        if let quantityIntValue = Int(quantityLabel), quantityIntValue > 1 {
            quantifiedItemFormattedString = String(
                format: Localization.accessibilityValueQuantityFormat,
                quantityIntValue,
                name
            )
        } else {
            quantifiedItemFormattedString = name
        }

        return quantifiedItemFormattedString + ". " + String(
            format: Localization.accessibilityValueFormat,
            detailsLabel,
            weightLabel,
            priceLabel
        )
    }

    enum Localization {
        static let accessibilityValueFormat = NSLocalizedString(
            "shipping_item_row.accessibility_value.format",
            value: "%1$@, Weight: %2$@, Total price: %3$@",
            comment: "Accessibility value for a shipping item row." +
            "Parameters are:%1$@: details, %2$@: weight, %3$@: price."
        )

        static let accessibilityValueQuantityFormat = NSLocalizedString(
            "shipping_item_row.quantity.format",
            value: "%1$d items of %2$@",
            comment: "Format for plural item quantity." +
            "Parameters are: %1$@: plural quantity, %2$@: item name."
        )
    }
}

private extension WooShippingItemRow {
    /// Displays a different badge background shape based on the item quantity
    /// Circular for 2-character quantities, rounded for 3-character quantities or more
    var badgeStyle: BadgeView.BackgroundShape {
        if quantityLabel.count < 3 {
            return .circle
        } else {
            return .roundedRectangle(cornerRadius: Layout.badgeOffset)
        }
    }

    enum Layout {
        static let horizontalSpacing: CGFloat = 16
        static let imageSize: CGFloat = 56.0
        static let imageCornerRadius: CGFloat = 4.0
        static let badgeOffset: CGFloat = 8.0
    }
}

#Preview {
    WooShippingItemRow(imageUrl: nil,
                       quantityLabel: "3",
                       name: "Little Nap Brazil 250g",
                       detailsLabel: "15×10×8cm • Espresso",
                       weightLabel: "275g",
                       priceLabel: "$60.00")
}
