import Foundation
import CoreData


extension ShipmentTrackingProvider {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShipmentTrackingProvider> {
        return NSFetchRequest<ShipmentTrackingProvider>(entityName: "ShipmentTrackingProvider")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var name: String?
    @NSManaged public var url: String?
    @NSManaged public var group: ShipmentTrackingProviderGroup?

}
