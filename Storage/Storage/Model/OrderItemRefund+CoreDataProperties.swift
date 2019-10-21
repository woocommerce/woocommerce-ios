import Foundation
import CoreData


extension OrderItemRefund {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderItemRefund> {
        return NSFetchRequest<OrderItemRefund>(entityName: "OrderItemRefund")
    }

    @NSManaged public var itemID: Int64
    @NSManaged public var name: String?
    @NSManaged public var productID: Int64
    @NSManaged public var variationID: Int64
    @NSManaged public var quantity: NSDecimalNumber?
    @NSManaged public var price: NSDecimalNumber?
    @NSManaged public var sku: String?
    @NSManaged public var subtotal: String?
    @NSManaged public var subtotalTax: String?
    @NSManaged public var taxClass: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var taxes: Set<OrderItemTaxRefund>?
    @NSManaged public var refund: Refund?

}

// MARK: Generated accessors for taxes
extension OrderItemRefund {

    @objc(addTaxesObject:)
    @NSManaged public func addToTaxes(_ value: OrderItemTaxRefund)

    @objc(removeTaxesObject:)
    @NSManaged public func removeFromTaxes(_ value: OrderItemTaxRefund)

    @objc(addTaxes:)
    @NSManaged public func addToTaxes(_ values: NSSet)

    @objc(removeTaxes:)
    @NSManaged public func removeFromTaxes(_ values: NSSet)

}
