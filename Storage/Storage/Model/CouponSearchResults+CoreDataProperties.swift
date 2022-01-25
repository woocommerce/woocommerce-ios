import Foundation
import CoreData

extension CouponSearchResults {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CouponSearchResults> {
        return NSFetchRequest<CouponSearchResults>(entityName: "CouponSearchResults")
    }

    @NSManaged public var keyword: String?
    @NSManaged public var coupon: Coupon?

}
