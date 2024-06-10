import Foundation
import protocol WooFoundation.Analytics

/// View model for `BlazeCreateCampaignIntroView`
final class BlazeCreateCampaignIntroViewModel: ObservableObject {
    private let analytics: Analytics

    @Published var showLearnHowSheet: Bool = false

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func onAppear() {
        analytics.track(event: .Blaze.introDisplayed())
    }

    func didTapLearnHowBlazeWorks() {
        showLearnHowSheet = true
        analytics.track(event: .Blaze.introLearnMoreTapped())
    }
}
