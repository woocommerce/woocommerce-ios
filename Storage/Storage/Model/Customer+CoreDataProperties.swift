import Foundation
import CoreData


extension Customer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        return NSFetchRequest<Customer>(entityName: "Customer")
    }

    @NSManaged public var customerID: Int64
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var customerName: String?

}

extension Customer: Identifiable {

}
