import Foundation
import CoreData

extension ShippingLineTax {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLineTax> {
        return NSFetchRequest<ShippingLineTax>(entityName: "ShippingLineTax")
    }

    @NSManaged public var taxID: Int64
    @NSManaged public var total: String?
    @NSManaged public var subtotal: String?
    @NSManaged public var shipping: ShippingLine?

}
