import CoreData
import CoreSpotlight
import WooFoundation

class CoreDataSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        debugPrint("object", object)

        if let product = object as? Product {
            return attributeSet(for: product)
        } else if let order = object as? Order {
            return attributeSet(for: order)
        }

        return nil
    }

    func attributeSet(for product: Product) -> CSSearchableItemAttributeSet? {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
          let tags = (product.tags?.array as? [ProductTag] ?? [])
              .compactMap { $0.name }
              .joined(separator: " ")
          attributeSet.textContent = String(product.productID) + " " + product.name + " " + tags
          attributeSet.displayName = "Woo Product: \(product.name)"
          attributeSet.contentDescription = product.briefDescription?.removedHTMLTags

        return attributeSet
    }

    func attributeSet(for order: Order) -> CSSearchableItemAttributeSet? {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
          attributeSet.displayName = "Woo Order #\(order.orderID): \(order.billingFirstName ?? "") \(order.billingLastName ?? "")"
    
        return attributeSet
    }
}
