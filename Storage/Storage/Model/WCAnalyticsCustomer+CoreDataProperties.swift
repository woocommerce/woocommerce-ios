import Foundation
import CoreData


extension WCAnalyticsCustomer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCAnalyticsCustomer> {
        return NSFetchRequest<WCAnalyticsCustomer>(entityName: "WCAnalyticsCustomer")
    }

    @NSManaged public var customerID: Int64
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var customerName: String?

}

extension WCAnalyticsCustomer: Identifiable {

}
