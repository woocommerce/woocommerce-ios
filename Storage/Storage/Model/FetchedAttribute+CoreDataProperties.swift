import Foundation
import CoreData


extension FetchedAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FetchedAttribute> {
        return NSFetchRequest<FetchedAttribute>(entityName: "Attribute")
    }

    @NSManaged public var id: Int64
    @NSManaged public var key: String
    @NSManaged public var value: String
    @NSManaged public var productVariation: ProductVariation?

}
