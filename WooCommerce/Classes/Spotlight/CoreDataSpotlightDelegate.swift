import CoreSpotlight
import WooFoundation
import Storage
import CoreData

/// Enables integration with Core Spotlight.
/// As we generate here UI content -display name, description, etc.-, we keep it in the main WooCommerce project
///
class CoreDataSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        if let product = object as? Product {
            return attributeSet(for: product)
        }

        return nil
    }

    private func attributeSet(for product: Product) -> CSSearchableItemAttributeSet? {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
          let tags = (product.tags?.array as? [ProductTag] ?? [])
              .compactMap { $0.name }
              .joined(separator: " ")
        attributeSet.textContent = String(product.productID) + " " + product.name + " " + tags
        attributeSet.displayName = product.name
        attributeSet.contentDescription = product.briefDescription?.removedHTMLTags

        return attributeSet
    }
}
