import Foundation
import CoreData


extension ProductAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductAttribute> {
        return NSFetchRequest<ProductAttribute>(entityName: "ProductAttribute")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var attributeID: Int64
    @NSManaged public var name: String
    @NSManaged public var position: Int64
    @NSManaged public var visible: Bool
    @NSManaged public var variation: Bool
    @NSManaged public var options: [String]?
    @NSManaged public var product: Product?

}
