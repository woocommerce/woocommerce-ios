import Foundation
import CoreData


extension ProductShippingClass {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductShippingClass> {
        return NSFetchRequest<ProductShippingClass>(entityName: "ProductShippingClass")
    }

    @NSManaged public var shippingClassID: Int64
    @NSManaged public var name: String
    @NSManaged public var slug: String
    @NSManaged public var descriptionHTML: String?
    @NSManaged public var count: Int64
    @NSManaged public var siteID: Int64

}
