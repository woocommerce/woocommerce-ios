import Foundation
import CoreData


extension OrderFulfillment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderFulfillment> {
        return NSFetchRequest<OrderFulfillment>(entityName: "OrderFulfillment")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var orderID: Int64
    @NSManaged public var fulfillmentID: Int64
    @NSManaged public var statusKey: String?
    @NSManaged public var isFulfilled: Bool
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var dateFulfilled: Date?
    @NSManaged public var trackingNumber: String?
    @NSManaged public var providerName: String?
    @NSManaged public var shipmentProvider: String?
    @NSManaged public var trackingURL: String?
    @NSManaged public var order: Order?
}
