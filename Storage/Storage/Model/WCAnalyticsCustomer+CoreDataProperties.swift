import Foundation
import CoreData


extension WCAnalyticsCustomer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCAnalyticsCustomer> {
        return NSFetchRequest<WCAnalyticsCustomer>(entityName: "WCAnalyticsCustomer")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var customerID: Int64
    @NSManaged public var userID: Int64
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var username: String?
    @NSManaged public var dateRegistered: Date?
    @NSManaged public var dateLastActive: Date?
    @NSManaged public var ordersCount: Int64
    @NSManaged public var totalSpend: NSDecimalNumber?
    @NSManaged public var averageOrderValue: NSDecimalNumber?
    @NSManaged public var country: String?
    @NSManaged public var region: String?
    @NSManaged public var city: String?
    @NSManaged public var postcode: String?
    @NSManaged public var searchResults: Set<WCAnalyticsCustomerSearchResult>?

}

// MARK: Generated accessors for searchResults
extension WCAnalyticsCustomer {

    @objc(addSearchResultsObject:)
    @NSManaged public func addToSearchResults(_ value: WCAnalyticsCustomerSearchResult)

    @objc(removeSearchResultsObject:)
    @NSManaged public func removeFromSearchResults(_ value: WCAnalyticsCustomerSearchResult)

    @objc(addSearchResults:)
    @NSManaged public func addToSearchResults(_ values: NSSet)

    @objc(removeSearchResults:)
    @NSManaged public func removeFromSearchResults(_ values: NSSet)

}

extension WCAnalyticsCustomer: Identifiable {

}
