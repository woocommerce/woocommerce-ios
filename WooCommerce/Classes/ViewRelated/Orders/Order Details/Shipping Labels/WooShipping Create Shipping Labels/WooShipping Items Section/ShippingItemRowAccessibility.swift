import Foundation

/// Reusable accessibility builder for `WooShippingItemRow` and `SelectableShipmentItemRo`
enum ShippingItemRowAccessibility {
    static func accessibilityValue(
        itemName: String,
        quantity: String,
        details: String,
        weight: String,
        price: String
    ) -> String {
        /// Covers item name and quantity if plural
        let quantifiedItemFormattedString: String
        if let quantityIntValue = Int(quantity), quantityIntValue > 1 {
            quantifiedItemFormattedString = String(
                format: Localization.accessibilityValueQuantityFormat,
                quantityIntValue,
                itemName
            )
        } else {
            quantifiedItemFormattedString = itemName
        }

        return quantifiedItemFormattedString + ". " + String(
            format: Localization.accessibilityValueFormat,
            details,
            weight,
            price
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
