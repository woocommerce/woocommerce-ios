import Foundation
import WooFoundation
import UIKit
import Yosemite
import Combine

final class JustInTimeMessageAnnouncementCardViewModel: AnnouncementCardViewModelProtocol {
    private let siteID: Int64

    private let analytics: Analytics

    // MARK: - Message properties
    let title: String

    let message: String

    let buttonTitle: String?

    private let url: URL?

    private let messageID: String

    private let featureClass: String

    private let screenName: String

    init(justInTimeMessage: YosemiteJustInTimeMessage,
         screenName: String,
         siteID: Int64,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        let utmProvider = WooCommerceComUTMProvider(
            campaign: "jitm_group_\(justInTimeMessage.featureClass)",
            source: screenName,
            content: "jitm_\(justInTimeMessage.messageID)",
            siteID: siteID)
        self.url = utmProvider.urlWithUtmParams(string: justInTimeMessage.url)
        self.messageID = justInTimeMessage.messageID
        self.featureClass = justInTimeMessage.featureClass
        self.screenName = screenName
        self.title = justInTimeMessage.title
        self.message = justInTimeMessage.detail
        self.buttonTitle = justInTimeMessage.buttonTitle
    }

    // MARK: - output streams
    @Published private(set) var showWebViewSheet: WebViewSheetViewModel?

    // MARK: - default AnnouncementCardViewModelProtocol conformance
    let showDividers: Bool = false

    let badgeType: BadgeView.BadgeType = .tip

    let image: UIImage = .paymentsFeatureBannerImage

    var showDismissButton: Bool = true

    let showDismissConfirmation: Bool = false

    let dismissAlertTitle: String = ""

    let dismissAlertMessage: String = ""

    // MARK: - AnnouncementCardViewModelProtocol methods
    func onAppear() {
        // No-op
    }

    func ctaTapped() {
        analytics.track(event: WooAnalyticsEvent.JustInTimeMessage.callToActionTapped(
            source: screenName,
            messageID: messageID,
            featureClass: featureClass))

        guard let url = url else {
            return
        }
        let webViewModel = WebViewSheetViewModel(
            url: url,
            navigationTitle: title,
            wpComAuthenticated: needsAuthenticatedWebView(url: url))
        showWebViewSheet = webViewModel
    }

    private func needsAuthenticatedWebView(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        return Constants.trustedDomains.contains(host)
    }

    func dontShowAgainTapped() {
        // No-op
    }

    func remindLaterTapped() {
        // No-op
    }
}

extension JustInTimeMessageAnnouncementCardViewModel {
    enum Constants {
        static let trustedDomains = ["woocommerce.com", "wordpress.com"]
    }
}
