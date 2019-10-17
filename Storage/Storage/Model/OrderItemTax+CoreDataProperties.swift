import Foundation
import CoreData


extension OrderItemTax {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderItemTax> {
        return NSFetchRequest<OrderItemTax>(entityName: "OrderItemTax")
    }

    @NSManaged public var taxID: Int64
    @NSManaged public var subtotal: String?
    @NSManaged public var total: String?
    @NSManaged public var item: OrderItem?

}
