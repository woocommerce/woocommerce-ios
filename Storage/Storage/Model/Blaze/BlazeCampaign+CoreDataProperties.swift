import Foundation
import CoreData


extension BlazeCampaign {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlazeCampaign> {
        return NSFetchRequest<BlazeCampaign>(entityName: "BlazeCampaign")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var campaignID: Int64
    @NSManaged public var productID: NSNumber?
    @NSManaged public var name: String
    @NSManaged public var rawStatus: String
    @NSManaged public var contentImageURL: String?
    @NSManaged public var contentClickURL: String?
    @NSManaged public var totalImpressions: Int64
    @NSManaged public var totalClicks: Int64
    @NSManaged public var totalBudget: Double

}
