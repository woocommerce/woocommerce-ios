import Foundation
import CoreData


extension OrderItemProductAddOn {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderItemProductAddOn> {
        return NSFetchRequest<OrderItemProductAddOn>(entityName: "OrderItemProductAddOn")
    }

    @NSManaged public var addOnID: NSNumber?
    @NSManaged public var key: String
    @NSManaged public var value: String
    @NSManaged public var orderItem: OrderItem?

}

extension OrderItemProductAddOn: Identifiable {

}
