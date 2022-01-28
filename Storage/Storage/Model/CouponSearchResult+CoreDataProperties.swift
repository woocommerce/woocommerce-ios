import Foundation
import CoreData

extension CouponSearchResult {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CouponSearchResult> {
        return NSFetchRequest<CouponSearchResult>(entityName: "CouponSearchResult")
    }

    @NSManaged public var keyword: String?
    @NSManaged public var coupons: NSSet?

}

// MARK: Generated accessors for coupons
extension CouponSearchResult {

    @objc(addCouponsObject:)
    @NSManaged public func addToCoupons(_ value: Coupon)

    @objc(removeCouponsObject:)
    @NSManaged public func removeFromCoupons(_ value: Coupon)

    @objc(addCoupons:)
    @NSManaged public func addToCoupons(_ values: NSSet)

    @objc(removeCoupons:)
    @NSManaged public func removeFromCoupons(_ values: NSSet)

}
