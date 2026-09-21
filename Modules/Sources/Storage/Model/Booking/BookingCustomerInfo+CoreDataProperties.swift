import Foundation
import CoreData

extension BookingCustomerInfo {
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
    @NSManaged public var note: String?
    @NSManaged public var orderInfo: BookingOrderInfo?
}
