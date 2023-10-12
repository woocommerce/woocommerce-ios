import Foundation
import Yosemite

extension BlazeCampaign: Identifiable {
    var id: String {
        campaignID
    }
}

/// View model for `BlazeCampaignListView`
final class BlazeCampaignListViewModel: ObservableObject {
    @Published private(set) var items: [BlazeCampaign] = []
}
