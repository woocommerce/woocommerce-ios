import CoreData
import Foundation

extension SiteVisitStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SiteVisitStats> {
        return NSFetchRequest<SiteVisitStats>(entityName: "SiteVisitStats")
    }

    @NSManaged public var date: String
    @NSManaged public var granularity: String
    @NSManaged public var items: Set<SiteVisitStatsItem>?
}

// MARK: Generated accessors for items
extension SiteVisitStats {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: SiteVisitStatsItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: SiteVisitStatsItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
