import Foundation
import UIKit
import Yosemite
import WooFoundation

private typealias FeatureCardEvent = WooAnalyticsEvent.FeatureCard

protocol AnnouncementCardViewModelProtocol {
    var showDividers: Bool { get }
    var badgeType: BadgeView.BadgeType { get }

    var title: String { get }
    var message: String { get }
    var buttonTitle: String? { get }

    /// `image` is the background/decorative image for the card.
    /// It will be used as a placeholder and/or fallback when `imageUrl` is specified
    var image: UIImage { get }

    /// `imageUrl` is used to load a remote image for the card, if specified.
    /// `image` will be used as the placeholder during loading
    var imageUrl: URL? { get }

    /// `imageUrl` is used to load a remote dark mode image for the card, if specified.
    /// `image` will be used as the placeholder during loading
    var imageDarkUrl: URL? { get }

    func onAppear()
    func ctaTapped()

    var showDismissConfirmation: Bool { get }
    var dismissAlertTitle: String { get }
    var dismissAlertMessage: String { get }
    func dontShowAgainTapped()
    func remindLaterTapped()
}

class FeatureAnnouncementCardViewModel: AnnouncementCardViewModelProtocol {
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

    var imageUrl: URL? {
        config.imageUrl
    }

    var imageDarkUrl: URL? {
        config.imageDarkUrl
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
        let remindAfterDays = remindLater ? 0 : nil
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: config.campaign,
                                                                       remindAfterDays: remindAfterDays,
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

    struct Configuration: Equatable {
        let source: WooAnalyticsEvent.FeatureCard.Source
        let campaign: FeatureAnnouncementCampaign
        let title: String
        let message: String
        let buttonTitle: String?
        let image: UIImage
        let imageUrl: URL?
        let imageDarkUrl: URL?
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
