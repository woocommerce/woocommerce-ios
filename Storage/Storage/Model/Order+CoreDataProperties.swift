import Foundation
import CoreData


extension Order {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Order> {
        return NSFetchRequest<Order>(entityName: "Order")
    }

    @NSManaged public var billingAddress1: String?
    @NSManaged public var billingAddress2: String?
    @NSManaged public var billingCity: String?
    @NSManaged public var billingCompany: String?
    @NSManaged public var billingCountry: String?
    @NSManaged public var billingEmail: String?
    @NSManaged public var billingFirstName: String?
    @NSManaged public var billingLastName: String?
    @NSManaged public var billingPhone: String?
    @NSManaged public var billingPostcode: String?
    @NSManaged public var billingState: String?
    @NSManaged public var currency: String?
    @NSManaged public var customerID: Int64
    @NSManaged public var customerNote: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var datePaid: Date?
    @NSManaged public var discountTax: String?
    @NSManaged public var discountTotal: String?
    @NSManaged public var exclusiveForSearch: Bool
    @NSManaged public var number: String?
    @NSManaged public var orderID: Int64
    @NSManaged public var parentID: Int64
    @NSManaged public var paymentMethodTitle: String?
    @NSManaged public var shippingAddress1: String?
    @NSManaged public var shippingAddress2: String?
    @NSManaged public var shippingCity: String?
    @NSManaged public var shippingCompany: String?
    @NSManaged public var shippingCountry: String?
    @NSManaged public var shippingEmail: String?
    @NSManaged public var shippingFirstName: String?
    @NSManaged public var shippingLastName: String?
    @NSManaged public var shippingPhone: String?
    @NSManaged public var shippingPostcode: String?
    @NSManaged public var shippingState: String?
    @NSManaged public var shippingTax: String?
    @NSManaged public var shippingTotal: String?
    @NSManaged public var shippingLines: Set<ShippingLine>?
    @NSManaged public var siteID: Int64
    @NSManaged public var statusKey: String
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var coupons: Set<OrderCoupon>?
    @NSManaged public var items: Set<OrderItem>?
    @NSManaged public var notes: Set<OrderNote>?
    @NSManaged public var searchResults: Set<OrderSearchResults>?
    @NSManaged public var refunds: Set<OrderRefundCondensed>?

}

// MARK: Generated accessors for shippingLines
extension Order {

    @objc(addShippingLinesObject:)
    @NSManaged public func addToShippingLines(_ value: ShippingLine)

    @objc(removeShippingLinesObject:)
    @NSManaged public func removeFromShippingLines(_ value: ShippingLine)

    @objc(addShippingLines:)
    @NSManaged public func addToShippingLines(_ values: NSSet)

    @objc(removeShippingLines:)
    @NSManaged public func removeFromShippingLines(_ values: NSSet)

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

// MARK: Generated accessors for notes
extension Order {

    @objc(addNotesObject:)
    @NSManaged public func addToNotes(_ value: OrderNote)

    @objc(removeNotesObject:)
    @NSManaged public func removeFromNotes(_ value: OrderNote)

    @objc(addNotes:)
    @NSManaged public func addToNotes(_ values: NSSet)

    @objc(removeNotes:)
    @NSManaged public func removeFromNotes(_ values: NSSet)

}

// MARK: Generated accessors for searchResults
extension Order {

    @objc(addSearchResultsObject:)
    @NSManaged public func addToSearchResults(_ value: OrderSearchResults)

    @objc(removeSearchResultsObject:)
    @NSManaged public func removeFromSearchResults(_ value: OrderSearchResults)

    @objc(addSearchResults:)
    @NSManaged public func addToSearchResults(_ values: NSSet)

    @objc(removeSearchResults:)
    @NSManaged public func removeFromSearchResults(_ values: NSSet)

}

// MARK: Generated accessors for refunds
extension Order {

    @objc(addRefundsObject:)
    @NSManaged public func addToRefunds(_ value: OrderRefundCondensed)

    @objc(removeRefundsObject:)
    @NSManaged public func removeFromRefunds(_ value: OrderRefundCondensed)

    @objc(addRefunds:)
    @NSManaged public func addToRefunds(_ values: NSSet)

    @objc(removeRefunds:)
    @NSManaged public func removeFromRefunds(_ values: NSSet)

}
