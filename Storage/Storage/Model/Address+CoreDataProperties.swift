import Foundation
import CoreData


extension Address {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Address> {
        return NSFetchRequest<Address>(entityName: "Address")
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var company: String?
    @NSManaged public var address1: String?
    @NSManaged public var address2: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var postcode: String?
    @NSManaged public var country: String?
    @NSManaged public var phone: String?
    @NSManaged public var email: String?
    @NSManaged public var billingOrder: Order?
    @NSManaged public var shippingOrder: Order?
}
