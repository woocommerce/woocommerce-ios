import Foundation
import CoreData


extension ShippingLabelSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabelSettings> {
        return NSFetchRequest<ShippingLabelSettings>(entityName: "ShippingLabelSettings")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var orderID: Int64
    @NSManaged public var paperSize: String
    @NSManaged public var order: Order?

}
