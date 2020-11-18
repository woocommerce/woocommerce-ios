import Foundation
import CoreData


extension ShippingLabelRefund {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabelRefund> {
        return NSFetchRequest<ShippingLabelRefund>(entityName: "ShippingLabelRefund")
    }

    @NSManaged public var dateRequested: Date
    @NSManaged public var status: String
    @NSManaged public var shippingLabel: ShippingLabel?

}
