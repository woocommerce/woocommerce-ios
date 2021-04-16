import Foundation
import Yosemite

/// ViewModel for `OrderAddOnListI1View`
///
final class OrderAddOnListI1ViewModel {
    /// AddOns to render
    ///
    let addOns: [OrderAddOnI1ViewModel]

    /// Navigation title
    ///
    let title = Localization.title

    /// Member-wise initializer, useful for `SwiftUI` previews
    ///
    init(addOns: [OrderAddOnI1ViewModel]) {
        self.addOns = addOns
    }

    /// Initializer: Converts order item attributes into add-on view models
    ///
    init(attributes: [OrderItemAttribute]) {
        self.addOns = attributes.map { attribute in
            let name = Self.addOnName(from: attribute)
            let price = Self.addOnPrice(from: attribute, withDecodedName: name)
            return OrderAddOnI1ViewModel(id: attribute.metaID, title: name, content: attribute.value, price: price)
        }
    }

    /// Decodes the name of the add-on from the `attribute.name` property.
    /// The `attribute.name` comes in the form of "add-on-title (add-on-price)". EG: "Topping (Spicy) ($30.00)"
    ///
    private static func addOnName(from attribute: OrderItemAttribute) -> String {
        attribute.name.components(separatedBy: " (") // "Topping (Spicy) ($30.00)" -> ["Topping", "Spicy)", "$30.00)"]
            .dropLast()                              // ["Topping", "Spicy)", "$30.00)"] -> ["Topping", "Spicy)"]
            .joined(separator: " (")                 // ["Topping", "Spicy)"] -> "Topping (Spicy)"
    }

    /// Decodes the price of the add-on from the `attribute.name` property using an already decoded add-on name.
    /// The `attribute.name` comes in the form of "add-on-title (add-on-price)". EG: "Topping (Spicy) ($30.00)"
    ///
    private static func addOnPrice(from attribute: OrderItemAttribute, withDecodedName name: String) -> String {
        attribute.name.replacingOccurrences(of: name, with: "")     // "Topping (Spicy) ($30.00)" -> " ($30.00)"
            .trimmingCharacters(in: CharacterSet([" ", "(", ")"]))  // " ($30.00)" -> "$30.00"
    }
}

// MARK: Constants
private extension OrderAddOnListI1ViewModel {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "The title on the navigation bar when viewing an order item add-ons")
    }
}


/// ViewModel for `OrderAddOnI1View`
///
struct OrderAddOnI1ViewModel: Identifiable, Equatable {
    /// Unique identifier, required by `SwiftUI`
    /// Discussion: Not using `UUID()` to not having to write a custom equality function.
    ///
    let id: Int64

    /// Add-on title
    ///
    let title: String

    /// Add-on content
    ///
    let content: String

    /// Add-on price
    ///
    let price: String
}
