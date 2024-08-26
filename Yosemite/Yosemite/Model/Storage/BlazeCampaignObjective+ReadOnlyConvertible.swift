import Foundation
import Storage

// MARK: - Storage.BlazeCampaignObjective: ReadOnlyConvertible
//
extension Storage.BlazeCampaignObjective: ReadOnlyConvertible {
    /// Updates the `Storage.BlazeCampaignObjective` from the ReadOnly representation (`Networking.BlazeCampaignObjective`)
    ///
    public func update(with objective: Yosemite.BlazeCampaignObjective) {
        id = objective.id
        title = objective.title
        generalDescription = objective.description
        suitableForDescription = objective.suitableForDescription
        locale = objective.locale
    }

    /// Returns a ReadOnly (`Networking.BlazeCampaignObjective`) version of the `Storage.BlazeCampaignObjective`
    ///
    public func toReadOnly() -> BlazeCampaignObjective {
        BlazeCampaignObjective(id: id,
                               title: title,
                               description: generalDescription,
                               suitableForDescription: suitableForDescription,
                               locale: locale)
    }
}
