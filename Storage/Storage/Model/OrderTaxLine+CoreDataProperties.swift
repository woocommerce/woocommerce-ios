import Foundation
import CoreData


extension OrderTaxLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderTaxLine> {
        return NSFetchRequest<OrderTaxLine>(entityName: "OrderTaxLine")
    }

    @NSManaged public var taxID: Int64
    @NSManaged public var rateCode: String?
    @NSManaged public var rateID: Int64
    @NSManaged public var label: String?
    @NSManaged public var isCompoundTaxRate: Bool
    @NSManaged public var totalTax: String?
    @NSManaged public var totalShippingTax: String?
    @NSManaged public var ratePercent: Double
    @NSManaged public var attributes: Set<OrderItemAttribute>?
    @NSManaged public var order: Order

}

// MARK: Generated accessors for attributes
extension OrderTaxLine {

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: OrderItemAttribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: OrderItemAttribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSSet)

}

extension OrderTaxLine: Identifiable {

}
