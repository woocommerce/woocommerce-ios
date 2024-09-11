import Foundation

// MARK: - Blaze campaign objective helpers
//
extension UserDefaults {
    /// Returns objective ID saved for campaign creation
    ///
    func retrieveSavedObjectiveID(for siteID: Int64) -> String? {
        let campaignObjective = self[.blazeSelectedCampaignObjective] as? [String: String]
        let idAsString = "\(siteID)"
        return campaignObjective?[idAsString]
    }

    /// Saves objective ID for future Blaze campaigns
    ///
    func saveObjectiveForFutureCampaigns(objectiveID: String,
                                         for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var campaignObjectiveDictionary = self[.blazeSelectedCampaignObjective] as? [String: String] {
            campaignObjectiveDictionary[idAsString] = objectiveID
            self[.blazeSelectedCampaignObjective] = campaignObjectiveDictionary
        } else {
            self[.blazeSelectedCampaignObjective] = [idAsString: objectiveID]
        }
    }
}
