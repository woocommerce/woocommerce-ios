import Foundation
import UIKit

struct JustInTimeMessageAnnouncementCardViewModel: AnnouncementCardViewModelProtocol {
    var showDividers: Bool = false

    var badgeType: BadgeView.BadgeType = .tip

    var title: String

    var message: String

    var buttonTitle: String?

    var image: UIImage = .paymentsFeatureBannerImage

    func onAppear() {
        // No-op
    }

    func ctaTapped() {
        // No-op
    }

    var showDismissButton: Bool = true

    var showDismissConfirmation: Bool = false

    var dismissAlertTitle: String = ""

    var dismissAlertMessage: String = ""

    func dontShowAgainTapped() {
        // No-op
    }

    func remindLaterTapped() {
        // No-op
    }

}
