import Foundation
import CoreData


extension OrderFeeLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderFeeLine> {
        return NSFetchRequest<OrderFeeLine>(entityName: "OrderFeeLine")
    }

    @NSManaged public var feeID: Int64
    @NSManaged public var name: String?
    @NSManaged public var taxClass: String?
    @NSManaged public var taxStatusKey: String
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var taxes: Set<OrderItemTax>?
    @NSManaged public var attributes: Set<OrderItemAttribute>?
    @NSManaged public var order: Order
}

// MARK: Generated accessors for taxes
extension OrderFeeLine {

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
extension OrderFeeLine {

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: OrderItemAttribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: OrderItemAttribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSSet)

}
