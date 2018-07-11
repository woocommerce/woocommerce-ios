import Foundation
import CoreData


extension Order {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Order> {
        return NSFetchRequest<Order>(entityName: "Order")
    }

    @NSManaged public var orderID: Int64
    @NSManaged public var parentID: Int64
    @NSManaged public var customerID: Int64
    @NSManaged public var number: String?
    @NSManaged public var status: String
    @NSManaged public var currency: String?
    @NSManaged public var customerNote: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var datePaid: Date?
    @NSManaged public var discountTotal: String?
    @NSManaged public var discountTax: String?
    @NSManaged public var shippingTotal: String?
    @NSManaged public var shippingTax: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var paymentMethodTitle: String?
    @NSManaged public var items: NSSet?
    @NSManaged public var billingAddress: Address?
    @NSManaged public var shippingAddress: Address?
    @NSManaged public var coupons: NSSet?

}

// MARK: Generated accessors for items
extension Order {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: OrderItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: OrderItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

// MARK: Generated accessors for coupons
extension Order {

    @objc(addCouponsObject:)
    @NSManaged public func addToCoupons(_ value: OrderCoupon)

    @objc(removeCouponsObject:)
    @NSManaged public func removeFromCoupons(_ value: OrderCoupon)

    @objc(addCoupons:)
    @NSManaged public func addToCoupons(_ values: NSSet)

    @objc(removeCoupons:)
    @NSManaged public func removeFromCoupons(_ values: NSSet)

}
