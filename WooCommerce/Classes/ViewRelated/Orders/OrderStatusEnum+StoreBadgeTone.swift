import StoreDesignSystem
import Yosemite

extension OrderStatusEnum {
    var storeBadgeTone: StoreBadgeTone {
        switch self {
        case .failed:
            .error
        case .onHold:
            .warning
        case .processing:
            .success
        case .completed:
            .info
        case .autoDraft, .pending, .cancelled, .refunded, .custom:
            .neutral
        }
    }
}
