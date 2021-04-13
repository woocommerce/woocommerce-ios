import Foundation
import Yosemite

/// Use case to cross-reference an order's items's attributes with a product's addOns list, to figure out which attributes of the order are real add ons.
///
struct AddOnCrossreferenceUseCase {

    /// Order item with unknown attributes
    ///
    private let orderItem: AggregateOrderItem

    /// Product entity with known addOns that matches the order item.
    ///
    private let product: Product

    init(orderItem: AggregateOrderItem, product: Product) {
        self.orderItem = orderItem
        self.product = product
    }

    /// Returns the attributes of an `orderItem` that are `addOns` by cross-referencing the attribute name with the addOn name.
    ///
    func addOnsAttributes() -> [OrderItemAttribute] {
        orderItem.attributes.filter { attribute in
            product.addOns.contains { $0.name == extractAddOnName(from: attribute) }
        }
    }

    /// Tries to extract the `addOn` name from an attribute where it's format it's `"add-on-title (add-on-price)"`
    ///
    private func extractAddOnName(from attribute: OrderItemAttribute) -> String {
        let splitToken = " ("
        let components = attribute.name.components(separatedBy: splitToken)

        // In case there are more `" ("` occurrences in the string, drop the last one assuming its the add-on price,
        // and join the remaining components to keep the original name integrity
        return components.dropLast().joined(separator: splitToken)
    }
}
