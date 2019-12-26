import Foundation
import CoreData


extension ShippingLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLine> {
        return NSFetchRequest<ShippingLine>(entityName: "ShippingLine")
    }

    @NSManaged public var shippingID: Int64
    @NSManaged public var methodTitle: String?
    @NSManaged public var methodID: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var order: Order?

}
