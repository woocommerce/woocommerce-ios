import Foundation
import CoreData


extension OrderAttributionInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderAttributionInfo> {
        return NSFetchRequest<OrderAttributionInfo>(entityName: "OrderAttributionInfo")
    }

    @NSManaged public var sourceType: String?
    @NSManaged public var campaign: String?
    @NSManaged public var source: String?
    @NSManaged public var medium: String?
    @NSManaged public var deviceType: String?
    @NSManaged public var sessionPageViews: String?
    @NSManaged public var order: Order?

}
