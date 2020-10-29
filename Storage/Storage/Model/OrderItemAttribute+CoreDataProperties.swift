import Foundation
import CoreData


extension OrderItemAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderItemAttribute> {
        return NSFetchRequest<OrderItemAttribute>(entityName: "OrderItemAttribute")
    }

    @NSManaged public var metaID: Int64
    @NSManaged public var name: String
    @NSManaged public var value: String
    @NSManaged public var orderItem: OrderItem?

}
