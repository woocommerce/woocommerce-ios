import Foundation
import CoreData


extension TopEarnerStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TopEarnerStats> {
        return NSFetchRequest<TopEarnerStats>(entityName: "TopEarnerStats")
    }

    @NSManaged public var period: String?
    @NSManaged public var granularity: String?
    @NSManaged public var limit: String?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var items: Set<TopEarnerStatsItem>?
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
