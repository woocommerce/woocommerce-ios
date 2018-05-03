import UIKit

extension UILabel {
    func applyTitleStyle() {
        font = .headline
        textColor = StyleManager.defaultTextColor
    }

    func applyBodyStyle() {
        font = .body
        textColor = StyleManager.defaultTextColor
    }

    func applyFootnoteStyle() {
        font = UIFont.footnote
        textColor = StyleManager.defaultTextColor
    }

    func applyStatusStyle(for statusString: String) {
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        font = .footnote;

        let status = OrderStatus(rawValue: statusString)

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
            case .canceled:
                fallthrough
            case .custom:
                fallthrough
            default:
                backgroundColor = StyleManager.statusNotIdentifiedColor
                layer.borderColor = StyleManager.statusNotIdentifiedBoldColor.cgColor
        }
    }
}
