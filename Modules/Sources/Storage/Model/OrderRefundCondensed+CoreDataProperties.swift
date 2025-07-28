import Foundation
import CoreData


extension OrderRefundCondensed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderRefundCondensed> {
        return NSFetchRequest<OrderRefundCondensed>(entityName: "OrderRefundCondensed")
    }

    @NSManaged public var refundID: Int64
    @NSManaged public var reason: String?
    @NSManaged public var total: String?
    @NSManaged public var order: Order?

}
