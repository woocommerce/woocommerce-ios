import CoreData
import Foundation

extension OrderStatsItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsItem> {
        return NSFetchRequest<OrderStatsItem>(entityName: "OrderStatsItem")
    }

    @NSManaged public var period: String?
    @NSManaged public var orders: Int64
    @NSManaged public var products: Int64
    @NSManaged public var coupons: Int64
    @NSManaged public var couponDiscount: Double
    @NSManaged public var totalSales: Double
    @NSManaged public var totalTax: Double
    @NSManaged public var totalShipping: Double
    @NSManaged public var totalShippingTax: Double
    @NSManaged public var totalRefund: Double
    @NSManaged public var totalTaxRefund: Double
    @NSManaged public var totalShippingRefund: Double
    @NSManaged public var totalShippingTaxRefund: Double
    @NSManaged public var currency: String?
    @NSManaged public var grossSales: Double
    @NSManaged public var netSales: Double
    @NSManaged public var avgOrderValue: Double
    @NSManaged public var avgProductsPerOrder: Double
    @NSManaged public var stats: OrderStats?
}
