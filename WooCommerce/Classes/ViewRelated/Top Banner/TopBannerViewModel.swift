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
    let isExpanded: Bool
    let topButton: TopButtonType

    let actionButtons: [ActionButton]

    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         isExpanded: Bool = true,
         topButton: TopButtonType,
         actionButtons: [ActionButton] = []) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.isExpanded = isExpanded
        self.topButton = topButton
        self.actionButtons = actionButtons
    }
}

struct ActionButton {
    let title: String
    let action: () -> Void
}
