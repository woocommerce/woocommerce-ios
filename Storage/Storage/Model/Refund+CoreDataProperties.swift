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
    @NSManaged public var supportShippingRefunds: Bool
    @NSManaged public var items: Set<OrderItemRefund>?
    @NSManaged public var shippingLines: Set<ShippingLine>?

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

// MARK: Generated accessors for shippingLines
extension Refund {

    @objc(addShippingLinesObject:)
    @NSManaged public func addToShippingLines(_ value: ShippingLine)

    @objc(removeShippingLinesObject:)
    @NSManaged public func removeFromShippingLines(_ value: ShippingLine)

    @objc(addShippingLines:)
    @NSManaged public func addToShippingLines(_ values: NSSet)

    @objc(removeShippingLines:)
    @NSManaged public func removeFromShippingLines(_ values: NSSet)

}
