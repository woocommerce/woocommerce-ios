import Foundation
import Yosemite

class OrderStatusViewModel {
    let orderStatus: OrderStatus

    init(orderStatus: OrderStatus) {
        self.orderStatus = orderStatus
    }

    var backgroundColor: UIColor {
        switch orderStatus {
        case .processing:
            fallthrough
        case .pending:
            return StyleManager.statusSuccessColor
        case .failed:
            fallthrough
        case .refunded:
            return StyleManager.statusDangerColor
        case .completed:
            return StyleManager.statusPrimaryColor
        case .onHold:
            fallthrough
        case .cancelled:
            fallthrough
        case .custom:
            fallthrough
        default:
            return StyleManager.statusNotIdentifiedColor
        }
    }

    var borderColor: CGColor {
        switch orderStatus {
        case .processing:
            fallthrough
        case .pending:
            return StyleManager.statusSuccessBoldColor.cgColor
        case .failed:
            fallthrough
        case .refunded:
            return StyleManager.statusDangerBoldColor.cgColor
        case .completed:
            return StyleManager.statusPrimaryBoldColor.cgColor
        case .onHold:
            fallthrough
        case .cancelled:
            fallthrough
        case .custom:
            fallthrough
        default:
            return StyleManager.statusNotIdentifiedBoldColor.cgColor
        }
    }
}
