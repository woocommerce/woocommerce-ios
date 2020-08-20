import UIKit

/// View model for `TopBannerView`.
///
struct TopBannerViewModel {

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

    enum BannerType {
        case normal
        case warning
    }

    let title: String?
    let infoText: String?
    let icon: UIImage?
    let actionButtonTitle: String?
    let isExpanded: Bool
    let actionHandler: (() -> Void)?
    let topButton: TopButtonType
    let type: BannerType

    /// Used when the top banner is not actionable.
    ///
    init(title: String?,
         infoText: String?,
         icon: UIImage?,
         isExpanded: Bool,
         topButton: TopButtonType,
         type: BannerType = .normal) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.isExpanded = isExpanded
        self.actionButtonTitle = nil
        self.actionHandler = nil
        self.topButton = topButton
        self.type = type
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
         type: BannerType = .normal) {
        self.title = title
        self.infoText = infoText
        self.icon = icon
        self.actionButtonTitle = actionButtonTitle
        self.isExpanded = isExpanded
        self.actionHandler = actionHandler
        self.topButton = topButton
        self.type = type
    }
}
