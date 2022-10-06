import Foundation
import CoreData


extension Customer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        return NSFetchRequest<Customer>(entityName: "Customer")
    }

    @NSManaged public var billing: String?
    @NSManaged public var customerID: Int64
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var shipping: String?
    @NSManaged public var username: String?
    @NSManaged public var id: CustomerSearchResult?

}

extension Customer: Identifiable {

}
