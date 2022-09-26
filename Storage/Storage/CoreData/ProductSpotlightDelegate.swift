import CoreData
import CoreSpotlight
import WooFoundation

class ProductSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
  override func domainIdentifier() -> String {
    return "com.raywenderlich.pointybug.bugs"
  }

  override func indexName() -> String? {
    return "bugs-index"
  }

  override func attributeSet(for object: NSManagedObject)
    -> CSSearchableItemAttributeSet? {
      guard let product = object as? Product else {
        return nil
      }

      let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        let tags = (product.tags?.array as? [ProductTag] ?? [])
            .compactMap { $0.name }
            .joined(separator: " ")
        attributeSet.textContent = String(product.productID) + " " + product.name + " " + tags
        attributeSet.displayName = "Woo Product: \(product.name)"
        attributeSet.contentDescription = product.briefDescription?.removedHTMLTags

      return attributeSet
  }
}
