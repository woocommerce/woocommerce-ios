import Foundation
import UIKit
import Yosemite

private typealias FeatureCardEvent = WooAnalyticsEvent.FeatureCard

struct FeatureAnnouncementCardViewModel {
    private let analytics: Analytics
    private let config: Configuration

    var title: String {
        config.title
    }

    var message: String {
        config.message
    }

    var buttonTitle: String {
        config.buttonTitle
    }

    var image: UIImage {
        config.image
    }

    init(analytics: Analytics,
         configuration: Configuration) {
        self.analytics = analytics
        self.config = configuration
    }

    func onAppear() {
        trackAnnouncementShown()
    }

    func dismissTapped() {
        trackAnnouncementDismissed()
    }

    func ctaTapped() {
        trackAnnouncementCtaTapped()
    }

    private func trackAnnouncementShown() {
        analytics.track(event: FeatureCardEvent.shown(source: config.source,
                                     campaign: config.campaign))
    }

    private func trackAnnouncementDismissed() {
        analytics.track(event: FeatureCardEvent.dismissed(source: config.source,
                                         campaign: config.campaign))
    }

    private func trackAnnouncementCtaTapped() {
        analytics.track(event: FeatureCardEvent.ctaTapped(source: config.source,
                                         campaign: config.campaign))
    }

    struct Configuration {
        let source: WooAnalyticsEvent.FeatureCard.Source
        let campaign: FeatureAnnouncementCampaign
        let title: String
        let message: String
        let buttonTitle: String
        let image: UIImage
    }
}
