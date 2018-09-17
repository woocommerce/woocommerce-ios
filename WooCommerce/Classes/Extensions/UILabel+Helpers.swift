import UIKit
import Yosemite


extension UILabel {
    func applyHeadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .headline
        textColor = StyleManager.defaultTextColor
    }

    func applySubheadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .subheadline
        textColor = StyleManager.defaultTextColor
    }

    func applyBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = StyleManager.defaultTextColor
    }

    func applyFootnoteStyle() {
        adjustsFontForContentSizeCategory = true
        font = .footnote
        textColor = StyleManager.defaultTextColor
    }

    func applyTitleStyle() {
        adjustsFontForContentSizeCategory = true
        font = .title1
        textColor = StyleManager.defaultTextColor
    }

    func applyStatusStyle(for status: OrderStatus) {
        adjustsFontForContentSizeCategory = true
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        font = .footnote

        switch status {
            case .processing:
                fallthrough
            case .pending:
                backgroundColor = StyleManager.statusSuccessColor
                layer.borderColor = StyleManager.statusSuccessBoldColor.cgColor
            case .failed:
                fallthrough
            case .refunded:
                backgroundColor = StyleManager.statusDangerColor
                layer.borderColor = StyleManager.statusDangerBoldColor.cgColor
            case .completed:
                backgroundColor = StyleManager.statusPrimaryColor
                layer.borderColor = StyleManager.statusPrimaryBoldColor.cgColor
            case .onHold:
                fallthrough
            case .cancelled:
                fallthrough
            case .custom:
                fallthrough
            default:
                backgroundColor = StyleManager.statusNotIdentifiedColor
                layer.borderColor = StyleManager.statusNotIdentifiedBoldColor.cgColor
        }
    }

    func applyPaddedLabelDefaultStyles() {
        adjustsFontForContentSizeCategory = true
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        font = .footnote
    }
}
