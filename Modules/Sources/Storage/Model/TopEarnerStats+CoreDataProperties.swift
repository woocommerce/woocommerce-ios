import Foundation
import CoreData


extension TopEarnerStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopEarnerStats> {
        return NSFetchRequest<TopEarnerStats>(entityName: "TopEarnerStats")
    }

    @NSManaged public var granularity: String
    @NSManaged public var limit: String
    @NSManaged public var date: String
    @NSManaged public var items: Set<TopEarnerStatsItem>?
    @NSManaged public var siteID: Int64
}

// MARK: Generated accessors for items
extension TopEarnerStats {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: TopEarnerStatsItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: TopEarnerStatsItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}
