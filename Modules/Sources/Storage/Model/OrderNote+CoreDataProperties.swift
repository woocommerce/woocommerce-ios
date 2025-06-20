import Foundation
import CoreData


extension OrderNote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderNote> {
        return NSFetchRequest<OrderNote>(entityName: "OrderNote")
    }

    @NSManaged public var noteID: Int64
    @NSManaged public var dateCreated: Date?
    @NSManaged public var note: String?
    @NSManaged public var isCustomerNote: Bool
    @NSManaged public var order: Order?
    @NSManaged public var author: String?
}
