import Foundation
import CoreData


extension TopEarnerStatsItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopEarnerStatsItem> {
        return NSFetchRequest<TopEarnerStatsItem>(entityName: "TopEarnerStatsItem")
    }

    @NSManaged public var productID: Int64
    @NSManaged public var productName: String?
    @NSManaged public var quantity: Int64
    @NSManaged public var total: Double
    @NSManaged public var currency: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var stats: TopEarnerStats?
}
