import Foundation
import CoreData


extension OrderCount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderCount> {
        return NSFetchRequest<OrderCount>(entityName: "OrderCount")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var items: Set<OrderCountItem>?

}

// MARK: Generated accessors for items
extension OrderCount {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: OrderCountItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: OrderCountItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: Set<OrderCountItem>)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: Set<OrderCountItem>)

}
