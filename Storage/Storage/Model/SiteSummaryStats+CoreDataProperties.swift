import Foundation
import CoreData


extension SiteSummaryStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SiteSummaryStats> {
        return NSFetchRequest<SiteSummaryStats>(entityName: "SiteSummaryStats")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var period: String
    @NSManaged public var date: String
    @NSManaged public var visitors: Int64
    @NSManaged public var views: Int64

}

extension SiteSummaryStats: Identifiable {

}
