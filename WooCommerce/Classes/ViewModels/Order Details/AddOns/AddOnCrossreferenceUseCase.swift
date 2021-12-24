import Foundation
import Yosemite

/// Use case to cross-reference an order's items's attributes with a product's addOns list and with the site's global add-ons.
/// To figure out which attributes of the order are real add-ons.
///
struct AddOnCrossreferenceUseCase {

    /// All of the order item attributes
    ///
    private let orderItemAttributes: [OrderItemAttribute]

    /// Product entity with known addOns that matches the order item.
    ///
    private let product: Product

    /// Global add-ons for the site.
    ///
    private let addOnGroups: [AddOnGroup]

    init(orderItemAttributes: [OrderItemAttribute], product: Product, addOnGroups: [AddOnGroup]) {
        self.orderItemAttributes = orderItemAttributes
        self.product = product
        self.addOnGroups = addOnGroups
    }

    /// Returns the attributes of an `orderItem` that are `addOns` by cross-referencing the attribute name with the add-on name.
    ///
    func addOnsAttributes() -> [OrderItemAttribute] {
        orderItemAttributes.filter { attribute in
            let addOnName = extractAddOnName(from: attribute)
            return addOnNameExistsInProductAddOns(addOnName) || addOnNameExistsInGlobalAddOns(addOnName)
        }
    }

    /// Tries to extract the `addOn` name from an attribute where it's format it's `"add-on-title (add-on-price)"`
    ///
    private func extractAddOnName(from attribute: OrderItemAttribute) -> String {
        let splitToken = " ("
        let components = attribute.name.components(separatedBy: splitToken)

        // If name does not match our format assumptions, return the raw name.
        guard components.count > 1 else {
            return attribute.name
        }

        // In case there are more `" ("` occurrences in the string, drop the last one assuming its the add-on price,
        // and join the remaining components to keep the original name integrity
        return components.dropLast().joined(separator: splitToken)
    }

    /// Returns wether if the provided add-on name matches any of the stored product add-ons
    ///
    private func addOnNameExistsInProductAddOns(_ name: String) -> Bool {
        product.addOns.contains { $0.name == name }
    }

    /// Returns wether if the provided add-on name matches any of the stored global add-ons
    ///
    private func addOnNameExistsInGlobalAddOns(_ name: String) -> Bool {
        let globalAddOns = addOnGroups.flatMap { $0.addOns }
        return globalAddOns.contains { $0.name == name }
    }
}
