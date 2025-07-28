import Foundation
import CoreData


extension ShipmentTracking {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShipmentTracking> {
        return NSFetchRequest<ShipmentTracking>(entityName: "ShipmentTracking")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var orderID: Int64
    @NSManaged public var trackingID: String
    @NSManaged public var trackingNumber: String?
    @NSManaged public var trackingProvider: String?
    @NSManaged public var trackingURL: String?
    @NSManaged public var dateShipped: Date?

}
