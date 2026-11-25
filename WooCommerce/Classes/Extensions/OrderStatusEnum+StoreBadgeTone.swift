import StoreDesignSystem
import Yosemite

extension OrderStatusEnum {
    var storeBadgeTone: StoreBadgeTone {
        switch self {
        case .processing:
            return .success
        case .completed:
            return .info
        case .onHold:
            return .warning
        case .failed:
            return .error
        case .autoDraft, .pending, .cancelled, .refunded, .custom:
            return .neutral
        }
    }
}
