import Foundation
import Codegen

public enum OrderPaymentStatusEnum: Codable, Hashable, Sendable, GeneratedFakeable {
    case unpaid
    case paid
    case partiallyRefunded
    case refunded
    case failed
    case custom(String)
}

extension OrderPaymentStatusEnum: RawRepresentable {
    public init(rawValue: String) {
        switch rawValue {
        case "unpaid":
            self = .unpaid
        case "paid":
            self = .paid
        case "partially_refunded":
            self = .partiallyRefunded
        case "refunded":
            self = .refunded
        case "failed":
            self = .failed
        default:
            self = .custom(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .unpaid: return "unpaid"
        case .paid: return "paid"
        case .partiallyRefunded: return "partially_refunded"
        case .refunded: return "refunded"
        case .failed: return "failed"
        case .custom(let value): return value
        }
    }
}

public extension OrderPaymentStatusEnum {
    var localizedName: String {
        switch self {
        case .unpaid:
            return NSLocalizedString(
                "orderPaymentStatus.localizedName.unpaid",
                value: "Unpaid",
                comment: "Display label for unpaid payment status."
            )
        case .paid:
            return NSLocalizedString(
                "orderPaymentStatus.localizedName.paid",
                value: "Paid",
                comment: "Display label for paid payment status."
            )
        case .partiallyRefunded:
            return NSLocalizedString(
                "orderPaymentStatus.localizedName.partiallyRefunded",
                value: "Partially Refunded",
                comment: "Display label for partially refunded payment status."
            )
        case .refunded:
            return NSLocalizedString(
                "orderPaymentStatus.localizedName.refunded",
                value: "Refunded",
                comment: "Display label for refunded payment status."
            )
        case .failed:
            return NSLocalizedString(
                "orderPaymentStatus.localizedName.failed",
                value: "Failed",
                comment: "Display label for failed payment status."
            )
        case .custom(let value):
            return value
        }
    }
}
