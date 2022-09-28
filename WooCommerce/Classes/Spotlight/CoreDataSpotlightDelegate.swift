import CoreSpotlight
import WooFoundation
import Storage
import CoreData

class CoreDataSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        if let product = object as? Product {
            return attributeSet(for: product)
        } else if let order = object as? Order {
            return attributeSet(for: order)
        }

        return nil
    }

    private func attributeSet(for product: Product) -> CSSearchableItemAttributeSet? {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
          let tags = (product.tags?.array as? [ProductTag] ?? [])
              .compactMap { $0.name }
              .joined(separator: " ")
        attributeSet.textContent = String(product.productID) + " " + product.name + " " + tags
        attributeSet.displayName = String.localizedStringWithFormat(Localization.productDisplayName, product.name)
        attributeSet.contentDescription = product.briefDescription?.removedHTMLTags

        return attributeSet
    }

    private func attributeSet(for order: Order) -> CSSearchableItemAttributeSet? {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.displayName = String.localizedStringWithFormat(Localization.orderDisplayName,
                                                                    order.orderID,
                                                                    order.billingFirstName ?? "",
                                                                    order.billingLastName ?? "")

        return attributeSet
    }

    private enum Localization {
        static let productDisplayName = NSLocalizedString("Woo Product: %1$@", comment: "Title for products items search in Spotlight")
        static let orderDisplayName = NSLocalizedString("Woo Order #%d %2$@ %3$@", comment: "Title for orders items search in Spotlight")
    }
}
