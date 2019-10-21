import CoreData
import Foundation

extension ProductTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductTag> {
        return NSFetchRequest<ProductTag>(entityName: "ProductTag")
    }

    @NSManaged public var tagID: Int64
    @NSManaged public var name: String
    @NSManaged public var slug: String
    @NSManaged public var product: Product?

}
