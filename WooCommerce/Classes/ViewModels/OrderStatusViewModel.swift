import Foundation
import Yosemite

class OrderStatusViewModel {
    let orderStatus: OrderStatus

    init(orderStatus: OrderStatus) {
        self.orderStatus = orderStatus
    }

    static var allOrderStatuses: [OrderStatus] {
        return [.pending, .processing, .onHold, .failed, .cancelled, .completed, .refunded, .custom(NSLocalizedString("Custom", comment: "Title for button that catches all custom labels and displays them on the order list"))]
    }

    static var allOrderStatusDescriptions: [String] {
        return allOrderStatuses.map { $0.description }
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
