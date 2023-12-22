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
        productID = nil // TODO: add a new attribute `productURL` and remove `productID`
        name = campaign.name
        rawStatus = campaign.uiStatus
        contentClickURL = campaign.contentClickURL
        contentImageURL = campaign.contentImageURL
        totalBudget = campaign.budgetCents // TODO: update the storage model property name
        totalClicks = campaign.totalClicks
        totalImpressions = campaign.totalImpressions
    }

    /// Returns a ReadOnly (`Networking.BlazeCampaign`) version of the `Storage.BlazeCampaign`
    ///
    public func toReadOnly() -> BlazeCampaign {
        BlazeCampaign(siteID: siteID,
                      campaignID: campaignID,
                      productURL: "", // TODO: map the new attribute `productURL` here
                      name: name,
                      uiStatus: rawStatus,
                      contentImageURL: contentImageURL,
                      contentClickURL: contentClickURL,
                      totalImpressions: totalImpressions,
                      totalClicks: totalClicks,
                      budgetCents: totalBudget)
    }
}
