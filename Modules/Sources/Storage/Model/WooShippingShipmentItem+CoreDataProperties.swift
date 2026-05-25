import Foundation
import CoreData

extension WooShippingShipmentItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingShipmentItem> {
        return NSFetchRequest<WooShippingShipmentItem>(entityName: "WooShippingShipmentItem")
    }

    @NSManaged public var id: Int64
    @NSManaged public var subItems: NSArray?
    @NSManaged public var shipment: WooShippingShipment?
}
