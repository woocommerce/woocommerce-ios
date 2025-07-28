import Foundation
import CoreData


extension OrderStatsV4Totals {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4Totals> {
        return NSFetchRequest<OrderStatsV4Totals>(entityName: "OrderStatsV4Totals")
    }

    @NSManaged public var totalOrders: Int64
    @NSManaged public var totalItemsSold: Int64
    @NSManaged public var grossRevenue: NSDecimalNumber
    @NSManaged public var netRevenue: NSDecimalNumber
    @NSManaged public var averageOrderValue: NSDecimalNumber
    @NSManaged public var interval: OrderStatsV4Interval?
    @NSManaged public var stats: OrderStatsV4?
}
