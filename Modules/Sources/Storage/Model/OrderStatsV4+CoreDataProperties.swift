import Foundation
import CoreData


extension OrderStatsV4 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4> {
        return NSFetchRequest<OrderStatsV4>(entityName: "OrderStatsV4")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var granularity: String
    @NSManaged public var timeRange: String
    @NSManaged public var totals: OrderStatsV4Totals?
    @NSManaged public var intervals: Set<OrderStatsV4Interval>?

}

// MARK: Generated accessors for intervals
extension OrderStatsV4 {

    @objc(addIntervalsObject:)
    @NSManaged public func addToIntervals(_ value: OrderStatsV4Interval)

    @objc(removeIntervalsObject:)
    @NSManaged public func removeFromIntervals(_ value: OrderStatsV4Interval)

    @objc(addIntervals:)
    @NSManaged public func addIntervals(_ values: NSSet)

    @objc(removeIntervals:)
    @NSManaged public func removeFromIntervals(_ values: NSSet)

}
