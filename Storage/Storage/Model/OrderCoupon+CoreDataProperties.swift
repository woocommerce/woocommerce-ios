import Foundation
import CoreData


extension OrderCoupon {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderCoupon> {
        return NSFetchRequest<OrderCoupon>(entityName: "OrderCoupon")
    }

    @NSManaged public var couponID: Int64
    @NSManaged public var code: String?
    @NSManaged public var discount: String?
    @NSManaged public var discountTax: String?
    @NSManaged public var order: Order
}
