import Foundation
import CoreData


extension OrderStatus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatus> {
        return NSFetchRequest<OrderStatus>(entityName: "OrderStatus")
    }

    @NSManaged public var name: String?
    @NSManaged public var slug: String?
    @NSManaged public var order: Order
}
