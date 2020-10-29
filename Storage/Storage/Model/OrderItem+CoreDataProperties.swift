import Foundation
import CoreData


extension OrderItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderItem> {
        return NSFetchRequest<OrderItem>(entityName: "OrderItem")
    }

    @NSManaged public var itemID: Int64
    @NSManaged public var name: String?
    @NSManaged public var price: NSDecimalNumber?
    @NSManaged public var productID: Int64
    @NSManaged public var quantity: NSDecimalNumber
    @NSManaged public var sku: String?
    @NSManaged public var subtotal: String?
    @NSManaged public var subtotalTax: String?
    @NSManaged public var taxClass: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var variationID: Int64
    @NSManaged public var order: Order
    @NSManaged public var taxes: Set<OrderItemTax>?
    @NSManaged public var attributes: NSOrderedSet?

}

// MARK: Generated accessors for taxes
extension OrderItem {

    @objc(addTaxesObject:)
    @NSManaged public func addToTaxes(_ value: OrderItemTax)

    @objc(removeTaxesObject:)
    @NSManaged public func removeFromTaxes(_ value: OrderItemTax)

    @objc(addTaxes:)
    @NSManaged public func addToTaxes(_ values: NSSet)

    @objc(removeTaxes:)
    @NSManaged public func removeFromTaxes(_ values: NSSet)

}

// MARK: Generated accessors for attributes
extension OrderItem {

    @objc(insertObject:inAttributesAtIndex:)
    @NSManaged public func insertIntoAttributes(_ value: OrderItemAttribute, at idx: Int)

    @objc(removeObjectFromAttributesAtIndex:)
    @NSManaged public func removeFromAttributes(at idx: Int)

    @objc(insertAttributes:atIndexes:)
    @NSManaged public func insertIntoAttributes(_ values: [OrderItemAttribute], at indexes: NSIndexSet)

    @objc(removeAttributesAtIndexes:)
    @NSManaged public func removeFromAttributes(at indexes: NSIndexSet)

    @objc(replaceObjectInAttributesAtIndex:withObject:)
    @NSManaged public func replaceAttributes(at idx: Int, with value: OrderItemAttribute)

    @objc(replaceAttributesAtIndexes:withAttributes:)
    @NSManaged public func replaceAttributes(at indexes: NSIndexSet, with values: [OrderItemAttribute])

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: OrderItemAttribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: OrderItemAttribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSOrderedSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSOrderedSet)

}
