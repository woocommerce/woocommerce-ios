import UIKit

extension UILabel {
    func applyStatusStyle(_ status: OrderStatus) {
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        font = UIFont.caption1;

        switch status {
            case .processing:
                fallthrough
            case .pending:
                backgroundColor = StyleManager.active.statusSuccessColor
                layer.borderColor = StyleManager.active.statusSuccessBoldColor.cgColor
            case .failed:
                fallthrough
            case .refunded:
                backgroundColor = StyleManager.active.statusDangerColor
                layer.borderColor = StyleManager.active.statusDangerBoldColor.cgColor
            case .completed:
                backgroundColor = StyleManager.active.statusPrimaryColor
                layer.borderColor = StyleManager.active.statusPrimaryBoldColor.cgColor
            case .onHold:
                fallthrough
            case .canceled:
                fallthrough
            default:
                backgroundColor = StyleManager.active.statusNotIdentifiedColor
                layer.borderColor = StyleManager.active.statusNotIdentifiedBoldColor.cgColor
        }
    }
}
