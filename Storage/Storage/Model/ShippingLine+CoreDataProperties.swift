import Foundation
import CoreData


extension ShippingLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLine> {
        return NSFetchRequest<ShippingLine>(entityName: "ShippingLine")
    }

    @NSManaged public var shippingId: Int64
    @NSManaged public var methodTitle: String?
    @NSManaged public var methodId: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    
}

// MARK: Generated accessors for providers
extension ShippingLine {

    @objc(addToShippingLinesObject:)
    @NSManaged public func addToShippingLines(_ value: ShippingLine)

    @objc(removeFromShippingLinesObject:)
    @NSManaged public func removeFromShippingLines(_ value: ShippingLine)

    @objc(addToShippingLines:)
    @NSManaged public func addToShippingLines(_ values: NSSet)

    @objc(removeFromShippingLines:)
    @NSManaged public func removeFromShippingLines(_ values: NSSet)

}
