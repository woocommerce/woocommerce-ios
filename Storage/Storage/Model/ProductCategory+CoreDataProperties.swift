import Foundation
import CoreData


extension ProductCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductCategory> {
        return NSFetchRequest<ProductCategory>(entityName: "ProductCategory")
    }

    @NSManaged public var categoryID: Int64
    @NSManaged public var siteID: Int64
    @NSManaged public var parentID: Int64
    @NSManaged public var name: String
    @NSManaged public var slug: String
    @NSManaged public var products: Set<Product>?
    @NSManaged public var includedInCoupons: Set<Coupon>?
    @NSManaged public var excludedFromCoupons: Set<Coupon>?

}

// MARK: Generated accessors for products
extension ProductCategory {

    @objc(addProductsObject:)
    @NSManaged public func addToProducts(_ value: Product)

    @objc(removeProductsObject:)
    @NSManaged public func removeFromProducts(_ value: Product)

    @objc(addProducts:)
    @NSManaged public func addToProducts(_ values: NSSet)

    @objc(removeProducts:)
    @NSManaged public func removeFromProducts(_ values: NSSet)

}

// MARK: Generated accessors for includedInCoupons
extension ProductCategory {

    @objc(addIncludedInCouponsObject:)
    @NSManaged public func addToIncludedInCoupons(_ value: Coupon)

    @objc(removeIncludedInCouponsObject:)
    @NSManaged public func removeFromIncludedInCoupons(_ value: Coupon)

    @objc(addIncludedInCoupons:)
    @NSManaged public func addToIncludedInCoupons(_ values: NSSet)

    @objc(removeIncludedInCoupons:)
    @NSManaged public func removeFromIncludedInCoupons(_ values: NSSet)

}

// MARK: Generated accessors for excludedFromCoupons
extension ProductCategory {

    @objc(addExcludedFromCouponsObject:)
    @NSManaged public func addToExcludedFromCoupons(_ value: Coupon)

    @objc(removeExcludedFromCouponsObject:)
    @NSManaged public func removeFromExcludedFromCoupons(_ value: Coupon)

    @objc(addExcludedFromCoupons:)
    @NSManaged public func addToExcludedFromCoupons(_ values: NSSet)

    @objc(removeExcludedFromCoupons:)
    @NSManaged public func removeFromExcludedFromCoupons(_ values: NSSet)

}
