import Foundation
import Storage

// MARK: - Storage.BriefBlazeCampaignInfo: ReadOnlyConvertible
//
extension Storage.BriefBlazeCampaignInfo: ReadOnlyConvertible {
    /// Updates the `Storage.BriefBlazeCampaignInfo` from the ReadOnly representation (`Networking.BriefBlazeCampaignInfo`)
    ///
    public func update(with campaign: Yosemite.BriefBlazeCampaignInfo) {
        siteID = campaign.siteID
        campaignID = campaign.campaignID
        productID = {
            guard let id = campaign.productID else {
                return nil
            }
            return NSNumber(value: id)
        }()
        name = campaign.name
        textSnippet = campaign.textSnippet
        rawStatus = campaign.uiStatus
        imageURL = campaign.imageURL
        targetUrl = campaign.targetUrl
        impressions = campaign.impressions
        clicks = campaign.clicks
        totalBudget = campaign.totalBudget
        spentBudget = campaign.spentBudget
    }

    /// Returns a ReadOnly (`Networking.BriefBlazeCampaignInfo`) version of the `Storage.BriefBlazeCampaignInfo`
    ///
    public func toReadOnly() -> BriefBlazeCampaignInfo {
        BriefBlazeCampaignInfo(siteID: siteID,
                               campaignID: campaignID,
                               productID: productID?.int64Value,
                               name: name,
                               textSnippet: textSnippet,
                               uiStatus: rawStatus,
                               imageURL: imageURL,
                               targetUrl: targetUrl,
                               impressions: impressions,
                               clicks: clicks,
                               totalBudget: totalBudget,
                               spentBudget: spentBudget)
    }
}
