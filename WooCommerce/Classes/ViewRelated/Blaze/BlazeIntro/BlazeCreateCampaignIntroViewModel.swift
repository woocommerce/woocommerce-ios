import Foundation

/// View model for `BlazeCreateCampaignIntroView`
final class BlazeCreateCampaignIntroViewModel: ObservableObject {
    private let analytics: Analytics

    @Published var showLearHowSheet: Bool = false

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func onLearnHowBlazeWorks() {
        showLearHowSheet = true
        // TODO: 11512 Track Learn how button tap
    }
}
