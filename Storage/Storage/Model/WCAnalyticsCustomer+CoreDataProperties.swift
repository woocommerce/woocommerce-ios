import Foundation
import CoreData


extension WCAnalyticsCustomer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCAnalyticsCustomer> {
        return NSFetchRequest<WCAnalyticsCustomer>(entityName: "WCAnalyticsCustomer")
    }

    @NSManaged public var customerID: String?
    @NSManaged public var username: String?
    @NSManaged public var orderID: NSSet?

}

// MARK: Generated accessors for orderID
extension WCAnalyticsCustomer {

    @objc(addOrderIDObject:)
    @NSManaged public func addToOrderID(_ value: Order)

    @objc(removeOrderIDObject:)
    @NSManaged public func removeFromOrderID(_ value: Order)

    @objc(addOrderID:)
    @NSManaged public func addToOrderID(_ values: NSSet)

    @objc(removeOrderID:)
    @NSManaged public func removeFromOrderID(_ values: NSSet)

}

extension WCAnalyticsCustomer: Identifiable {

}
