import Foundation
import CoreData


extension ProductCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductCategory> {
        return NSFetchRequest<ProductCategory>(entityName: "ProductCategory")
    }

    @NSManaged public var categoryID: Int64
    @NSManaged public var name: String
    @NSManaged public var slug: String
    @NSManaged public var product: Product?

}
