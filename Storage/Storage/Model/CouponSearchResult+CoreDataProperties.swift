import Foundation
import CoreData

extension CouponSearchResult {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CouponSearchResult> {
        return NSFetchRequest<CouponSearchResult>(entityName: "CouponSearchResult")
    }

    @NSManaged public var keyword: String?
    @NSManaged public var coupon: Coupon?

}
