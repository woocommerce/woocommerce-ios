import Foundation
import Storage

// MARK: - Storage.BlazeCampaignListItem: ReadOnlyConvertible
//
extension Storage.BlazeCampaignListItem: ReadOnlyConvertible {
    /// Updates the `Storage.BlazeCampaignListItem` from the ReadOnly representation (`Networking.BlazeCampaignListItem`)
    ///
    public func update(with campaign: Yosemite.BlazeCampaignListItem) {
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
        // TODO-12301: map values between storage and networking models for budget fields
    }

    /// Returns a ReadOnly (`Networking.BlazeCampaignListItem`) version of the `Storage.BlazeCampaignListItem`
    ///
    public func toReadOnly() -> BlazeCampaignListItem {
        // TODO-12301: map values between storage and networking models for budget fields
        BlazeCampaignListItem(siteID: siteID,
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
                              spentBudget: spentBudget,
                              budgetMode: .total,
                              budgetAmount: 0,
                              budgetCurrency: "USD")
    }
}
