import Foundation
import Storage

// MARK: - Storage.BlazeCampaign: ReadOnlyConvertible
//
extension Storage.BlazeCampaign: ReadOnlyConvertible {
    /// Updates the `Storage.BlazeCampaign` from the ReadOnly representation (`Networking.BlazeCampaign`)
    ///
    public func update(with campaign: Yosemite.BlazeCampaign) {
        siteID = campaign.siteID
        campaignID = campaign.campaignID
        name = campaign.name
        rawStatus = campaign.uiStatus
        contentClickURL = campaign.contentClickURL
        contentImageURL = campaign.contentImageURL
        totalBudget = campaign.totalBudget
        totalClicks = campaign.totalClicks
        totalImpressions = campaign.totalImpressions
    }

    /// Returns a ReadOnly (`Networking.BlazeCampaign`) version of the `Storage.BlazeCampaign`
    ///
    public func toReadOnly() -> BlazeCampaign {
        BlazeCampaign(siteID: siteID,
                      campaignID: campaignID,
                      productID: 0, // TODO-11059: update storage
                      name: name,
                      uiStatus: rawStatus,
                      contentImageURL: contentImageURL,
                      contentClickURL: contentClickURL,
                      totalImpressions: totalImpressions,
                      totalClicks: totalClicks,
                      totalBudget: totalBudget)
    }
}
