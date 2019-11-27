import UIKit

/// View model for `TopBannerView`.
///
struct TopBannerViewModel {
    let title: String?
    let infoText: String?
    let icon: UIImage?
    let actionButtonTitle: String?
    let actionHandler: (() -> Void)?
    let dismissHandler: (() -> Void)?

    /// Used when the top banner is not actionable.
    ///
    init(title: String?,
         infoText: String?,
         icon: UIImage?) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.actionButtonTitle = nil
        self.actionHandler = nil
        self.dismissHandler = nil
    }

    /// Used when the top banner is actionable.
    ///
    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         actionButtonTitle: String,
         actionHandler: @escaping () -> Void,
         dismissHandler: @escaping () -> Void) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.actionButtonTitle = actionButtonTitle
        self.actionHandler = actionHandler
        self.dismissHandler = dismissHandler
    }
}
