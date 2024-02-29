import Foundation
import CoreData


extension BlazeCampaignListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlazeCampaignListItem> {
        return NSFetchRequest<BlazeCampaignListItem>(entityName: "BlazeCampaignListItem")
    }

    @NSManaged public var campaignID: String
    @NSManaged public var clicks: Int64
    @NSManaged public var imageURL: String?
    @NSManaged public var impressions: Int64
    @NSManaged public var name: String
    @NSManaged public var productID: NSNumber?
    @NSManaged public var siteID: Int64
    @NSManaged public var spentBudget: Double
    @NSManaged public var targetUrl: String?
    @NSManaged public var textSnippet: String
    @NSManaged public var totalBudget: Double
    @NSManaged public var rawStatus: String

}

extension BlazeCampaignListItem: Identifiable {

}
