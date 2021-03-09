import UIKit

/// View model for `TopBannerSwifty`.
///
struct TopBannerSwiftyViewModel {

    enum TopButtonType {
        case chevron(handler: (() -> Void)?)
        case dismiss(handler: (() -> Void)?)
        case none

        var handler: (() -> Void)? {
            switch self {
            case let .chevron(handler), let .dismiss(handler):
                return handler
            case .none:
                return nil
            }
        }
    }

    /// Represents an actionable button with a title and an action
    ///
    struct ActionButton {
        let title: String
        let action: () -> Void
    }

    enum BannerType {
        case normal
        case warning
    }

    let title: String?
    let infoText: String?
    let icon: UIImage?
    let expandable: Bool
    let topButton: TopButtonType
    let actionButtons: [ActionButton]
    let type: BannerType

    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         expandable: Bool = true,
         topButton: TopButtonType,
         actionButtons: [ActionButton] = [],
         type: BannerType = .normal) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.expandable = expandable
        self.topButton = topButton
        self.actionButtons = actionButtons
        self.type = type
    }
}
