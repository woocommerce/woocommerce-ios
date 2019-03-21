import Foundation
import CoreData


extension ProductDefaultAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductDefaultAttribute> {
        return NSFetchRequest<ProductDefaultAttribute>(entityName: "ProductDefaultAttribute")
    }

    @NSManaged public var attributeID: Int64
    @NSManaged public var name: String?
    @NSManaged public var option: String?
    @NSManaged public var product: Product?

}
