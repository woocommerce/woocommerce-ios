import Foundation
import CoreData


extension ShippingLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLine> {
        return NSFetchRequest<ShippingLine>(entityName: "ShippingLine")
    }

    @NSManaged public var shippingID: Int64
    @NSManaged public var methodTitle: String?
    @NSManaged public var methodID: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var order: Order?
    @NSManaged public var taxes: Set<ShippingLineTax>?
    @NSManaged public var refund: Refund?

}

// MARK: Generated accessors for taxes
extension ShippingLine {

    @objc(addTaxesObject:)
    @NSManaged public func addToTaxes(_ value: ShippingLineTax)

    @objc(removeTaxesObject:)
    @NSManaged public func removeFromTaxes(_ value: ShippingLineTax)

    @objc(addTaxes:)
    @NSManaged public func addToTaxes(_ values: NSSet)

    @objc(removeTaxes:)
    @NSManaged public func removeFromTaxes(_ values: NSSet)

}
