import Foundation
import CoreData


extension OrderItemRefundMetadata {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderItemRefundMetadata> {
        return NSFetchRequest<OrderItemRefundMetadata>(entityName: "OrderItemRefundMetadata")
    }

    @NSManaged public var key: String?
    @NSManaged public var value: String?
}
