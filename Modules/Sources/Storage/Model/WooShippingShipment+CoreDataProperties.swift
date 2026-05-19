import Foundation
import CoreData

extension WooShippingShipment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingShipment> {
        return NSFetchRequest<WooShippingShipment>(entityName: "WooShippingShipment")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var orderID: Int64
    @NSManaged public var index: String
    @NSManaged public var shippingLabel: ShippingLabel?
    @NSManaged public var items: Set<WooShippingShipmentItem>?
    @NSManaged public var order: Order?
}

// MARK: Generated accessors for items
extension WooShippingShipment {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: WooShippingShipmentItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: WooShippingShipmentItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}
