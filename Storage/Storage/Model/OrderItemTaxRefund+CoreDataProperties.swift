import Foundation
import CoreData


extension OrderItemTaxRefund {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderItemTaxRefund> {
        return NSFetchRequest<OrderItemTaxRefund>(entityName: "OrderItemTaxRefund")
    }

    @NSManaged public var taxID: Int64
    @NSManaged public var subtotal: String?
    @NSManaged public var total: String?
    @NSManaged public var item: OrderItemRefund?

}
