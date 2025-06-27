import Foundation
import CoreData


extension OrderSearchResults {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderSearchResults> {
        return NSFetchRequest<OrderSearchResults>(entityName: "OrderSearchResults")
    }

    @NSManaged public var keyword: String?
    @NSManaged public var orders: Set<Order>?

}

// MARK: Generated accessors for orders
extension OrderSearchResults {

    @objc(addOrdersObject:)
    @NSManaged public func addToOrders(_ value: Order)

    @objc(removeOrdersObject:)
    @NSManaged public func removeFromOrders(_ value: Order)

    @objc(addOrders:)
    @NSManaged public func addToOrders(_ values: NSSet)

    @objc(removeOrders:)
    @NSManaged public func removeFromOrders(_ values: NSSet)

}
