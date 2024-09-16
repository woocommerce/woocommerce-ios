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
    @NSManaged public var chargeID: String?
    @NSManaged public var currency: String?
    @NSManaged public var customerID: Int64
    @NSManaged public var customerNote: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var datePaid: Date?
    @NSManaged public var discountTax: String?
    @NSManaged public var discountTotal: String?
    @NSManaged public var exclusiveForSearch: Bool
    @NSManaged public var fees: Set<OrderFeeLine>?
    @NSManaged public var isEditable: Bool
    @NSManaged public var needsPayment: Bool
    @NSManaged public var needsProcessing: Bool
    @NSManaged public var number: String?
    @NSManaged public var orderID: Int64
    @NSManaged public var parentID: Int64
    @NSManaged public var orderKey: String
    @NSManaged public var paymentMethodID: String?
    @NSManaged public var paymentMethodTitle: String?
    @NSManaged public var paymentURL: NSURL?
    @NSManaged public var renewalSubscriptionID: String?
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
    @NSManaged public var appliedGiftCards: Set<OrderGiftCard>?
    @NSManaged public var coupons: Set<OrderCoupon>?
    @NSManaged public var customFields: Set<MetaData>?
    @NSManaged public var items: NSOrderedSet?
    @NSManaged public var notes: Set<OrderNote>?
    @NSManaged public var searchResults: Set<OrderSearchResults>?
    @NSManaged public var refunds: Set<OrderRefundCondensed>?
    @NSManaged public var shippingLabels: Set<ShippingLabel>?
    @NSManaged public var shippingLabelSettings: ShippingLabelSettings?
    @NSManaged public var taxes: Set<OrderTaxLine>?
    @NSManaged public var attributionInfo: OrderAttributionInfo?

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

// MARK: Generated accessors for customFields
extension Order {

    @objc(addCustomFieldsObject:)
    @NSManaged public func addToCustomFields(_ value: MetaData)

    @objc(removeCustomFieldsObject:)
    @NSManaged public func removeFromCustomFields(_ value: MetaData)

    @objc(addCustomFields:)
    @NSManaged public func addToCustomFields(_ values: NSSet)

    @objc(removeCustomFields:)
    @NSManaged public func removeFromCustomFields(_ values: NSSet)

}

// MARK: Generated accessors for items
extension Order {

    @objc(insertObject:inItemsAtIndex:)
    @NSManaged public func insertIntoItems(_ value: OrderItem, at idx: Int)

    @objc(removeObjectFromItemsAtIndex:)
    @NSManaged public func removeFromItems(at idx: Int)

    @objc(insertItems:atIndexes:)
    @NSManaged public func insertIntoItems(_ values: [OrderItem], at indexes: NSIndexSet)

    @objc(removeItemsAtIndexes:)
    @NSManaged public func removeFromItems(at indexes: NSIndexSet)

    @objc(replaceObjectInItemsAtIndex:withObject:)
    @NSManaged public func replaceItems(at idx: Int, with value: OrderItem)

    @objc(replaceItemsAtIndexes:withItems:)
    @NSManaged public func replaceItems(at indexes: NSIndexSet, with values: [OrderItem])

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: OrderItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: OrderItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSOrderedSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSOrderedSet)

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

// MARK: Generated accessors for shippingLabels
extension Order {

    @objc(addShippingLabelsObject:)
    @NSManaged public func addToShippingLabels(_ value: ShippingLabel)

    @objc(removeShippingLabelsObject:)
    @NSManaged public func removeFromShippingLabels(_ value: ShippingLabel)

    @objc(addShippingLabels:)
    @NSManaged public func addToShippingLabels(_ values: NSSet)

    @objc(removeShippingLabels:)
    @NSManaged public func removeFromShippingLabels(_ values: NSSet)

}

// MARK: Generated accessors for fees
extension Order {

    @objc(addFeesObject:)
    @NSManaged public func addToFees(_ value: OrderFeeLine)

    @objc(removeFeesObject:)
    @NSManaged public func removeFromFees(_ value: OrderFeeLine)

    @objc(addFees:)
    @NSManaged public func addToFees(_ values: NSSet)

    @objc(removeFees:)
    @NSManaged public func removeFromFees(_ values: NSSet)

}

// MARK: Generated accessors for taxes
extension Order {

    @objc(addTaxesObject:)
    @NSManaged public func addToTaxes(_ value: OrderTaxLine)

    @objc(removeTaxesObject:)
    @NSManaged public func removeFromTaxes(_ value: OrderTaxLine)

    @objc(addTaxes:)
    @NSManaged public func addToTaxes(_ values: NSSet)

    @objc(removeTaxes:)
    @NSManaged public func removeFromTaxes(_ values: NSSet)

}

// MARK: Generated accessors for appliedGiftCards
extension Order {

    @objc(addAppliedGiftCardsObject:)
    @NSManaged public func addToAppliedGiftCards(_ value: OrderGiftCard)

    @objc(removeAppliedGiftCardsObject:)
    @NSManaged public func removeFromAppliedGiftCards(_ value: OrderGiftCard)

    @objc(addAppliedGiftCards:)
    @NSManaged public func addToAppliedGiftCards(_ values: NSSet)

    @objc(removeAppliedGiftCards:)
    @NSManaged public func removeFromAppliedGiftCards(_ values: NSSet)

}
