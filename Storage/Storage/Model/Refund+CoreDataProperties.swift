import Foundation
import CoreData


extension Refund {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Refund> {
        return NSFetchRequest<Refund>(entityName: "Refund")
    }

    @NSManaged public var refundID: Int64
    @NSManaged public var orderID: Int64
    @NSManaged public var siteID: Int64
    @NSManaged public var dateCreated: Date?
    @NSManaged public var amount: String?
    @NSManaged public var reason: String?
    @NSManaged public var byUserID: Int64
    @NSManaged public var isAutomated: Bool
    @NSManaged public var createAutomated: Bool
    @NSManaged public var items: Set<OrderItemRefund>?

}

// MARK: Generated accessors for items
extension Refund {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: OrderItemRefund)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: OrderItemRefund)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
