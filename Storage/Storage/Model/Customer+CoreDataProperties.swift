import Foundation
import CoreData


extension Customer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        return NSFetchRequest<Customer>(entityName: "Customer")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var userID: Int64
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date?
    @NSManaged public var email: String
    @NSManaged public var username: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var avatarUrl: String?
    @NSManaged public var role: String
    @NSManaged public var isPaying: Bool
    @NSManaged public var billingFirstName: String?
    @NSManaged public var billingLastName: String?
    @NSManaged public var billingCompany: String?
    @NSManaged public var billingAddress2: String?
    @NSManaged public var billingCity: String?
    @NSManaged public var billingState: String?
    @NSManaged public var billingPostcode: String?
    @NSManaged public var billingCountry: String?
    @NSManaged public var billingPhone: String?
    @NSManaged public var billingEmail: String?
    @NSManaged public var billingAddress1: String?
    @NSManaged public var shippingFirstName: String?
    @NSManaged public var shippingLastName: String?
    @NSManaged public var shippingCompany: String?
    @NSManaged public var shippingAddress1: String?
    @NSManaged public var shippingAddress2: String?
    @NSManaged public var shippingCity: String?
    @NSManaged public var shippingState: String?
    @NSManaged public var shippingPostcode: String?
    @NSManaged public var shippingCountry: String?
    @NSManaged public var shippingPhone: String?
    @NSManaged public var shippingEmail: String?

}
