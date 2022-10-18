import Foundation
import CoreData


extension Customer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        return NSFetchRequest<Customer>(entityName: "Customer")
    }

    @NSManaged public var billingAddress1: String?
    @NSManaged public var billingAddress2: String?
    @NSManaged public var billingCity: String?
    @NSManaged public var billingCompany: String?
    @NSManaged public var billingCountry: String?
    @NSManaged public var billingEmail: String?
    @NSManaged public var billingFirstName: String?
    @NSManaged public var billingLastName: String?
    @NSManaged public var billingPhone: String?
    @NSManaged public var billingPostcode: String?
    @NSManaged public var billingState: String?
    @NSManaged public var customerID: Int64
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var shippingAddress1: String?
    @NSManaged public var shippingAddress2: String?
    @NSManaged public var shippingCity: String?
    @NSManaged public var shippingCompany: String?
    @NSManaged public var shippingCountry: String?
    @NSManaged public var shippingEmail: String?
    @NSManaged public var shippingFirstName: String?
    @NSManaged public var shippingLastName: String?
    @NSManaged public var shippingPhone: String?
    @NSManaged public var shippingPostcode: String?
    @NSManaged public var shippingState: String?
    @NSManaged public var siteID: Int64
    @NSManaged public var searchResults: Set<CustomerSearchResult>?
}

// MARK: Generated accessors for searchResults
extension Customer {

    @objc(addSearchResultsObject:)
    @NSManaged public func addToSearchResults(_ value: CustomerSearchResult)

    @objc(removeSearchResultsObject:)
    @NSManaged public func removeFromSearchResults(_ value: CustomerSearchResult)

    @objc(addSearchResults:)
    @NSManaged public func addToSearchResults(_ values: NSSet)

    @objc(removeSearchResults:)
    @NSManaged public func removeFromSearchResults(_ values: NSSet)
}
