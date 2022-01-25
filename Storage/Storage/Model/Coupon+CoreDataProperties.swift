import Foundation
import CoreData


extension Coupon {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Coupon> {
        return NSFetchRequest<Coupon>(entityName: "Coupon")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var couponID: Int64
    @NSManaged public var code: String?
    @NSManaged public var amount: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var discountType: String?
    @NSManaged public var fullDescription: String?
    @NSManaged public var dateExpires: Date?
    @NSManaged public var usageCount: Int64
    @NSManaged public var individualUse: Bool
    @NSManaged public var usageLimit: Int64
    @NSManaged public var usageLimitPerUser: Int64
    @NSManaged public var limitUsageToXItems: Int64
    @NSManaged public var freeShipping: Bool
    @NSManaged public var excludeSaleItems: Bool
    @NSManaged public var minimumAmount: String?
    @NSManaged public var maximumAmount: String?
    @NSManaged public var emailRestrictions: [String]?
    @NSManaged public var usedBy: [String]?
    @NSManaged public var excludedProductCategories: [Int64]?
    @NSManaged public var excludedProducts: [Int64]?
    @NSManaged public var products: [Int64]?
    @NSManaged public var productCategories: [Int64]?

}

extension Coupon {

    @objc(addSearchResultsObject:)
    @NSManaged public func addToSearchResults(_ value: CouponSearchResults)

    @objc(removeSearchResultsObject:)
    @NSManaged public func removeFromSearchResults(_ value: CouponSearchResults)

    @objc(addSearchResults:)
    @NSManaged public func addToSearchResults(_ values: NSSet)

    @objc(removeSearchResults:)
    @NSManaged public func removeFromSearchResults(_ values: NSSet)

}
