import Foundation
import CoreData


extension OrderCountItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderCountItem> {
        return NSFetchRequest<OrderCountItem>(entityName: "OrderCountItem")
    }

    @NSManaged public var slug: String?
    @NSManaged public var name: String?
    @NSManaged public var total: Int64
    @NSManaged public var orderCount: OrderCount?

}
