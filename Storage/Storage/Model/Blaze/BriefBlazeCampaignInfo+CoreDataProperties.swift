import Foundation
import CoreData


extension BriefBlazeCampaignInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BriefBlazeCampaignInfo> {
        return NSFetchRequest<BriefBlazeCampaignInfo>(entityName: "BriefBlazeCampaignInfo")
    }

    @NSManaged public var campaignID: String?
    @NSManaged public var clicks: Int64
    @NSManaged public var imageURL: String?
    @NSManaged public var impressions: Int64
    @NSManaged public var name: String?
    @NSManaged public var productID: Int64
    @NSManaged public var siteID: Int64
    @NSManaged public var spentBudget: Double
    @NSManaged public var targetUrl: String?
    @NSManaged public var textSnippet: String?
    @NSManaged public var totalBudget: Double
    @NSManaged public var uiStatus: String?

}

extension BriefBlazeCampaignInfo: Identifiable {

}
