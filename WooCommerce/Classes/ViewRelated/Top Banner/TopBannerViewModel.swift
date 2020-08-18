import UIKit

/// View model for `TopBannerView`.
///
struct TopBannerViewModel {

    enum TopButtonType {
        case chevron(handler: (() -> Void)?)
        case dismiss(handler: (() -> Void)?)

        var handler: (() -> Void)? {
            switch self {
            case let .chevron(handler), let .dismiss(handler):
                return handler
            }
        }
    }

    let title: String?
    let infoText: String?
    let icon: UIImage?
    let actionButtonTitle: String?
    let isExpanded: Bool
    let actionHandler: (() -> Void)?
    let topButton: TopButtonType

    let actionButtons: [ActionButton]

    /// Used when the top banner is not actionable.
    ///
    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         isExpanded: Bool,
         topButton: TopButtonType) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.isExpanded = isExpanded
        self.actionButtonTitle = nil
        self.actionHandler = nil
        self.topButton = topButton
        self.actionButtons = []
    }

    /// Used when the top banner is actionable.
    ///
    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         actionButtonTitle: String,
         isExpanded: Bool = true,
         actionHandler: @escaping () -> Void,
         topButton: TopButtonType,
         actionButtons: [ActionButton]) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.actionButtonTitle = actionButtonTitle
        self.isExpanded = isExpanded
        self.actionHandler = actionHandler
        self.topButton = topButton
        self.actionButtons = actionButtons
    }
}

struct ActionButton {
    let title: String
    let action: () -> Void
}
