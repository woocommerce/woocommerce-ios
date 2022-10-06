import Foundation
import CoreData


extension CustomerSearchResult {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomerSearchResult> {
        return NSFetchRequest<CustomerSearchResult>(entityName: "CustomerSearchResult")
    }

    @NSManaged public var customerID: Int64
    @NSManaged public var customerName: String?
    @NSManaged public var email: String?
    @NSManaged public var keyword: String?
    @NSManaged public var id: Customer?

}

extension CustomerSearchResult: Identifiable {

}
