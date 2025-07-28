import Foundation
import CoreData


extension ProductTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductTag> {
        return NSFetchRequest<ProductTag>(entityName: "ProductTag")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var tagID: Int64
    @NSManaged public var name: String
    @NSManaged public var slug: String
    @NSManaged public var products: Set<Product>?

}

// MARK: Generated accessors for products
extension ProductTag {

    @objc(addProductsObject:)
    @NSManaged public func addToProducts(_ value: Product)

    @objc(removeProductsObject:)
    @NSManaged public func removeFromProducts(_ value: Product)

    @objc(addProducts:)
    @NSManaged public func addToProducts(_ values: NSSet)

    @objc(removeProducts:)
    @NSManaged public func removeFromProducts(_ values: NSSet)

}
