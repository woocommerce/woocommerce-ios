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
    @NSManaged public var products: Set<Product>?
    @NSManaged public var excludedProducts: Set<Product>?
    @NSManaged public var productCategories: Set<ProductCategory>?
    @NSManaged public var excludedProductCategories: Set<ProductCategory>?

}

// MARK: Generated accessors for products
extension Coupon {

    @objc(addProductsObject:)
    @NSManaged public func addToProducts(_ value: Product)

    @objc(removeProductsObject:)
    @NSManaged public func removeFromProducts(_ value: Product)

    @objc(addProducts:)
    @NSManaged public func addToProducts(_ values: NSSet)

    @objc(removeProducts:)
    @NSManaged public func removeFromProducts(_ values: NSSet)

}

// MARK: Generated accessors for excludedProducts
extension Coupon {

    @objc(addExcludedProductsObject:)
    @NSManaged public func addToExcludedProducts(_ value: Product)

    @objc(removeExcludedProductsObject:)
    @NSManaged public func removeFromExcludedProducts(_ value: Product)

    @objc(addExcludedProducts:)
    @NSManaged public func addToExcludedProducts(_ values: NSSet)

    @objc(removeExcludedProducts:)
    @NSManaged public func removeFromExcludedProducts(_ values: NSSet)

}

// MARK: Generated accessors for productCategories
extension Coupon {

    @objc(addProductCategoriesObject:)
    @NSManaged public func addToProductCategories(_ value: ProductCategory)

    @objc(removeProductCategoriesObject:)
    @NSManaged public func removeFromProductCategories(_ value: ProductCategory)

    @objc(addProductCategories:)
    @NSManaged public func addToProductCategories(_ values: NSSet)

    @objc(removeProductCategories:)
    @NSManaged public func removeFromProductCategories(_ values: NSSet)

}

// MARK: Generated accessors for excludedProductCategories
extension Coupon {

    @objc(addExcludedProductCategoriesObject:)
    @NSManaged public func addToExcludedProductCategories(_ value: ProductCategory)

    @objc(removeExcludedProductCategoriesObject:)
    @NSManaged public func removeFromExcludedProductCategories(_ value: ProductCategory)

    @objc(addExcludedProductCategories:)
    @NSManaged public func addToExcludedProductCategories(_ values: NSSet)

    @objc(removeExcludedProductCategories:)
    @NSManaged public func removeFromExcludedProductCategories(_ values: NSSet)

}

extension Coupon: Identifiable {

}
