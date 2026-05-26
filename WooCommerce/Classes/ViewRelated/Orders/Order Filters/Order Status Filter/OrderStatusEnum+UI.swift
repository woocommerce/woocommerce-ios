import UIKit
import enum Yosemite.OrderStatusEnum

extension OrderStatusEnum {
    var backgroundColor: UIColor {
        switch self {
        case .autoDraft, .pending, .cancelled, .refunded:
                .gray(.shade5)
        case .onHold:
                .withColorStudio(.orange, shade: .shade5)
        case .processing:
                .withColorStudio(.green, shade: .shade5)
        case .failed:
                .withColorStudio(.red, shade: .shade5)
        case .completed:
                .withColorStudio(.blue, shade: .shade5)
        case .custom(let slug):
            slug == CIABOrderStatusMapper.openSlug
                ? .withColorStudio(.orange, shade: .shade5)
                : .gray(.shade5)
        }
    }
}
