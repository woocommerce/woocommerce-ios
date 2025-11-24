import Foundation
import Codegen

public enum OrderPaymentStatusEnum: Codable, Hashable, Sendable, GeneratedFakeable {
    case unpaid
    case paid
    case partiallyRefunded
    case refunded
    case failed
    case unknown
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
            self = .unknown
        }
    }

    public var rawValue: String {
        switch self {
        case .unpaid: return "unpaid"
        case .paid: return "paid"
        case .partiallyRefunded: return "partially_refunded"
        case .refunded: return "refunded"
        case .failed: return "failed"
        case .unknown: return "unknown"
        }
    }
}
