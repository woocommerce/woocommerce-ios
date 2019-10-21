import CoreData
import Foundation

extension OrderStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStats> {
        return NSFetchRequest<OrderStats>(entityName: "OrderStats")
    }

    @NSManaged public var date: String
    @NSManaged public var granularity: String
    @NSManaged public var quantity: String?
    @NSManaged public var totalGrossSales: Double
    @NSManaged public var totalNetSales: Double
    @NSManaged public var totalOrders: Int64
    @NSManaged public var totalProducts: Int64
    @NSManaged public var averageGrossSales: Double
    @NSManaged public var averageNetSales: Double
    @NSManaged public var averageOrders: Double
    @NSManaged public var averageProducts: Double
    @NSManaged public var items: Set<OrderStatsItem>?
}

// MARK: Generated accessors for items
extension OrderStats {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: OrderStatsItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: OrderStatsItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
