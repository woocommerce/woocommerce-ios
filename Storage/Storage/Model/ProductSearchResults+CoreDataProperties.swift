import Foundation
import CoreData


extension ProductSearchResults {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductSearchResults> {
        return NSFetchRequest<ProductSearchResults>(entityName: "ProductSearchResults")
    }

    @NSManaged public var keyword: String?
    @NSManaged public var products: Set<Product>?

}

// MARK: Generated accessors for products
extension ProductSearchResults {

    @objc(addProductsObject:)
    @NSManaged public func addToProducts(_ value: Product)

    @objc(removeProductsObject:)
    @NSManaged public func removeFromProducts(_ value: Product)

    @objc(addProducts:)
    @NSManaged public func addToProducts(_ values: NSSet)

    @objc(removeProducts:)
    @NSManaged public func removeFromProducts(_ values: NSSet)

}
