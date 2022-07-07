import Foundation

private typealias FeatureCardEvent = WooAnalyticsEvent.FeatureCard

struct FeatureAnnouncementViewModel {
    private let analytics: Analytics
    private let source: FeatureCardEvent.Source
    private let campaign: FeatureCardEvent.Campaign

    init(analytics: Analytics,
         source: WooAnalyticsEvent.FeatureCard.Source,
         campaign: WooAnalyticsEvent.FeatureCard.Campaign) {
        self.analytics = analytics
        self.source = source
        self.campaign = campaign
    }

    func onAppear() {
        trackAnnouncementShown()
    }

    func dismissedTapped() {
        trackAnnouncementDismissed()
    }

    func ctaTapped() {
        trackAnnouncementCtaTapped()
    }

    private func trackAnnouncementShown() {
        analytics.track(event: FeatureCardEvent.shown(source: source, campaign: campaign))
    }

    private func trackAnnouncementDismissed() {
        analytics.track(event: FeatureCardEvent.dismissed(source: source, campaign: campaign))
    }

    private func trackAnnouncementCtaTapped() {
        analytics.track(event: FeatureCardEvent.ctaTapped(source: source, campaign: campaign))
    }
}
