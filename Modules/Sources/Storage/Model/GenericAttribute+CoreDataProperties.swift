import Foundation
import CoreData


extension GenericAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GenericAttribute> {
        return NSFetchRequest<GenericAttribute>(entityName: "GenericAttribute")
    }

    @NSManaged public var id: Int64
    @NSManaged public var key: String
    @NSManaged public var value: String
    @NSManaged public var productVariation: ProductVariation?

}
