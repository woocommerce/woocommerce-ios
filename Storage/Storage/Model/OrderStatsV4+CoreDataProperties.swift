import Foundation
import CoreData


extension OrderStatsV4 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4> {
        return NSFetchRequest<OrderStatsV4>(entityName: "OrderStatsV4")
    }

    @NSManaged public var siteID: Int
    @NSManaged public var granularity: String
    @NSManaged public var totals: OrderStatsV4Totals?
    @NSManaged public var intervals: NSOrderedSet?

}

// MARK: Generated accessors for intervals
extension OrderStatsV4 {

    @objc(insertObject:inIntervalsAtIndex:)
    @NSManaged public func insertIntoIntervals(_ value: OrderStatsV4Interval, at idx: Int)

    @objc(removeObjectFromIntervalsAtIndex:)
    @NSManaged public func removeFromIntervals(at idx: Int)

    @objc(insertIntervals:atIndexes:)
    @NSManaged public func insertIntoIntervals(_ values: [OrderStatsV4Interval], at indexes: NSIndexSet)

    @objc(removeIntervalsAtIndexes:)
    @NSManaged public func removeFromIntervals(at indexes: NSIndexSet)

    @objc(replaceObjectInIntervalsAtIndex:withObject:)
    @NSManaged public func replaceIntervals(at idx: Int, with value: OrderStatsV4Interval)

    @objc(replaceIntervalsAtIndexes:withIntervals:)
    @NSManaged public func replaceIntervals(at indexes: NSIndexSet, with values: [OrderStatsV4Interval])

    @objc(addIntervalsObject:)
    @NSManaged public func addToIntervals(_ value: OrderStatsV4Interval)

    @objc(removeIntervalsObject:)
    @NSManaged public func removeFromIntervals(_ value: OrderStatsV4Interval)

    @objc(addIntervals:)
    @NSManaged public func addToIntervals(_ values: NSOrderedSet)

    @objc(removeIntervals:)
    @NSManaged public func removeFromIntervals(_ values: NSOrderedSet)
}
