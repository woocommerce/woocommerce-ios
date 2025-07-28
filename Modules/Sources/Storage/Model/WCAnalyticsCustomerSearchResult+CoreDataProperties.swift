import Foundation
import CoreData


extension WCAnalyticsCustomerSearchResult {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCAnalyticsCustomerSearchResult> {
        return NSFetchRequest<WCAnalyticsCustomerSearchResult>(entityName: "WCAnalyticsCustomerSearchResult")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var keyword: String?
    @NSManaged public var customers: Set<WCAnalyticsCustomer>?

}

// MARK: Generated accessors for customers
extension WCAnalyticsCustomerSearchResult {

    @objc(addCustomersObject:)
    @NSManaged public func addToCustomers(_ value: WCAnalyticsCustomer)

    @objc(removeCustomersObject:)
    @NSManaged public func removeFromCustomers(_ value: WCAnalyticsCustomer)

    @objc(addCustomers:)
    @NSManaged public func addToCustomers(_ values: NSSet)

    @objc(removeCustomers:)
    @NSManaged public func removeFromCustomers(_ values: NSSet)

}

extension WCAnalyticsCustomerSearchResult: Identifiable {

}
