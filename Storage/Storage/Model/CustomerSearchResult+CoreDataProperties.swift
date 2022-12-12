import Foundation
import CoreData


extension CustomerSearchResult {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomerSearchResult> {
        return NSFetchRequest<CustomerSearchResult>(entityName: "CustomerSearchResult")
    }

    @NSManaged public var keyword: String
    @NSManaged public var siteID: Int64
    @NSManaged public var customers: Set<Customer>?
}

// MARK: Generated accessors for customers
extension CustomerSearchResult {

    @objc(addCustomersObject:)
    @NSManaged public func addToCustomers(_ value: Customer)

    @objc(removeCustomersObject:)
    @NSManaged public func removeFromCustomers(_ value: Customer)

    @objc(addCustomers:)
    @NSManaged public func addToCustomers(_ values: NSSet)

    @objc(removeCustomers:)
    @NSManaged public func removeFromCustomers(_ values: NSSet)
}
