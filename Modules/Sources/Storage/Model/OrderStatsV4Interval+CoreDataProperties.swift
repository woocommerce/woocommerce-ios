import Foundation
import CoreData


extension OrderStatsV4Interval {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4Interval> {
        return NSFetchRequest<OrderStatsV4Interval>(entityName: "OrderStatsV4Interval")
    }

    @NSManaged public var interval: String?
    @NSManaged public var dateStart: String?
    @NSManaged public var dateEnd: String?
    @NSManaged public var subtotals: OrderStatsV4Totals?
    @NSManaged public var stats: OrderStatsV4?
}
