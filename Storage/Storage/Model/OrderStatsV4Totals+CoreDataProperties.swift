import Foundation
import CoreData


extension OrderStatsV4Totals {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4Totals> {
        return NSFetchRequest<OrderStatsV4Totals>(entityName: "OrderStatsV4Totals")
    }

    @NSManaged public var totalOrders: Int64
    @NSManaged public var totalItemsSold: Int64
    @NSManaged public var grossRevenue: Decimal
    @NSManaged public var couponDiscount: Decimal
    @NSManaged public var totalCoupons: Int64
    @NSManaged public var refunds: Decimal
    @NSManaged public var taxes: Decimal
    @NSManaged public var shipping: Decimal
    @NSManaged public var netRevenue: Decimal
    @NSManaged public var totalProducts: Int64
    @NSManaged public var interval: OrderStatsV4Interval?
    @NSManaged public var stats: OrderStatsV4?
}
