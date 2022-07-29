import Foundation
import UIKit
import Yosemite

private typealias FeatureCardEvent = WooAnalyticsEvent.FeatureCard

class FeatureAnnouncementCardViewModel {
    private let analytics: Analytics
    private let config: Configuration

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

    var showDismissConfirmation: Bool {
        config.showDismissConfirmation
    }

    var dismissAlertTitle: String {
        config.dismissAlertTitle
    }

    var dismissAlertMessage: String {
        config.dismissAlertMessage
    }

    var showDividers: Bool {
        config.showDividers
    }

    var badgeType: BadgeView.BadgeType {
        config.badgeType
    }

    private(set) var shouldBeVisible: Bool = false

    init(analytics: Analytics,
         configuration: Configuration) {
        self.analytics = analytics
        self.config = configuration

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
        ServiceLocator.stores.dispatch(action)
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
        ServiceLocator.stores.dispatch(action)
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

    struct Configuration: Equatable {
        let source: WooAnalyticsEvent.FeatureCard.Source
        let campaign: FeatureAnnouncementCampaign
        let title: String
        let message: String
        let buttonTitle: String?
        let image: UIImage
        let showDismissConfirmation: Bool
        let dismissAlertTitle: String
        let dismissAlertMessage: String
        let showDividers: Bool
        let badgeType: BadgeView.BadgeType
    }
}

extension FeatureAnnouncementCardViewModel: Equatable {
    static func == (lhs: FeatureAnnouncementCardViewModel, rhs: FeatureAnnouncementCardViewModel) -> Bool {
        lhs.config == rhs.config
    }
}
