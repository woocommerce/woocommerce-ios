import Foundation
import UIKit
import Yosemite

private typealias FeatureCardEvent = WooAnalyticsEvent.FeatureCard

class FeatureAnnouncementCardViewModel {
    private let analytics: Analytics
    private let config: Configuration
    private let stores: StoresManager

    var title: String {
        config.title
    }

    var message: String {
        config.message
    }

    var buttonTitle: String? {
        config.buttonTitle
    }

    var image: UIImage {
        config.image
    }

    var dismissAlertTitle: String {
        config.dismissAlertTitle
    }

    var dismissAlertMessage: String {
        config.dismissAlertMessage
    }

    @Published private(set) var shouldBeVisible: Bool = false

    init(analytics: Analytics,
         configuration: Configuration,
         stores: StoresManager = ServiceLocator.stores) {
        self.analytics = analytics
        self.config = configuration
        self.stores = stores

        updateShouldBeVisible()
    }

    private func updateShouldBeVisible() {
        let action = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: config.campaign) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let visible):
                self.shouldBeVisible = visible
            case .failure:
                self.shouldBeVisible = false
            }
        }

        stores.dispatch(action)
    }

    func onAppear() {
        trackAnnouncementShown()
    }

    func dontShowAgainTapped() {
        storeDismissedSetting(remindLater: false)
        trackAnnouncementDismissed(remindLater: false)
    }

    func remindLaterTapped() {
        storeDismissedSetting(remindLater: true)
        trackAnnouncementDismissed(remindLater: true)
    }

    private func storeDismissedSetting(remindLater: Bool) {
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: config.campaign,
                                                                       remindLater: remindLater,
                                                                       onCompletion: nil)
        stores.dispatch(action)
        shouldBeVisible = false
    }

    func ctaTapped() {
        trackAnnouncementCtaTapped()
    }

    private func trackAnnouncementShown() {
        analytics.track(event: FeatureCardEvent.shown(source: config.source,
                                                      campaign: config.campaign))
    }

    private func trackAnnouncementDismissed(remindLater: Bool) {
        analytics.track(event: FeatureCardEvent.dismissed(source: config.source,
                                                          campaign: config.campaign,
                                                          remindLater: remindLater))
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
        let buttonTitle: String?
        let image: UIImage
        let dismissAlertTitle: String
        let dismissAlertMessage: String
    }
}
