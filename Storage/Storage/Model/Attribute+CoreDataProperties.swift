import Foundation
import CoreData


extension Attribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attribute> {
        return NSFetchRequest<Attribute>(entityName: "Attribute")
    }

    @NSManaged public var id: Int64
    @NSManaged public var key: String
    @NSManaged public var value: String
    @NSManaged public var productVariation: ProductVariation?

}
