import Foundation
import CoreData


extension OrderStatsV4Totals {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4Totals> {
        return NSFetchRequest<OrderStatsV4Totals>(entityName: "OrderStatsV4Totals")
    }

    @NSManaged public var totalOrders: Int64
    @NSManaged public var totalItemsSold: Int64
    @NSManaged public var grossRevenue: NSDecimalNumber
    @NSManaged public var couponDiscount: NSDecimalNumber
    @NSManaged public var totalCoupons: Int64
    @NSManaged public var refunds: NSDecimalNumber
    @NSManaged public var taxes: NSDecimalNumber
    @NSManaged public var shipping: NSDecimalNumber
    @NSManaged public var netRevenue: NSDecimalNumber
    @NSManaged public var totalProducts: Int64
    @NSManaged public var interval: OrderStatsV4Interval?
    @NSManaged public var stats: OrderStatsV4?
}
