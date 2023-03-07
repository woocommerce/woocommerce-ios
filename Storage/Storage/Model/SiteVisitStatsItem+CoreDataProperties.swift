import Foundation
import CoreData


extension SiteVisitStatsItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SiteVisitStatsItem> {
        return NSFetchRequest<SiteVisitStatsItem>(entityName: "SiteVisitStatsItem")
    }

    @NSManaged public var period: String?
    @NSManaged public var visitors: Int64
    @NSManaged public var views: Int64
    @NSManaged public var stats: SiteVisitStats?
}
