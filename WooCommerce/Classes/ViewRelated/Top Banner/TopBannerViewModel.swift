import UIKit

/// View model for `TopBannerView`.
///
struct TopBannerViewModel {
    let title: String?
    let infoText: String?
    let icon: UIImage?
    let actionButtonTitle: String?
    let isExpanded: Bool
    let actionHandler: (() -> Void)?
    let dismissHandler: (() -> Void)?
    let expandedStateChangeHandler: (() -> Void)?

    /// Used when the top banner is not actionable.
    ///
    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         isExpanded: Bool = true,
         expandedStateChangeHandler: (() -> Void)?) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.isExpanded = isExpanded
        self.actionButtonTitle = nil
        self.actionHandler = nil
        self.dismissHandler = nil
        self.expandedStateChangeHandler = expandedStateChangeHandler
    }

    /// Used when the top banner is actionable.
    ///
    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         actionButtonTitle: String,
         isExpanded: Bool = true,
         actionHandler: @escaping () -> Void,
         dismissHandler: @escaping () -> Void) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.actionButtonTitle = actionButtonTitle
        self.isExpanded = isExpanded
        self.actionHandler = actionHandler
        self.dismissHandler = dismissHandler
        self.expandedStateChangeHandler = nil
    }
}
