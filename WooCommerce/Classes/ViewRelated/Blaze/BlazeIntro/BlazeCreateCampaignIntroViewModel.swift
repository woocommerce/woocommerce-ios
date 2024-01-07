import Foundation

/// View model for `BlazeCreateCampaignIntroView`
final class BlazeCreateCampaignIntroViewModel: ObservableObject {
    private let analytics: Analytics

    @Published var showLearnHowSheet: Bool = false

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func onLearnHowBlazeWorks() {
        showLearnHowSheet = true
        // TODO: 11512 Track Learn how button tap
    }
}
