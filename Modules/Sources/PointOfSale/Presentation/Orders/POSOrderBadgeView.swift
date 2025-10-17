import SwiftUI
import struct Yosemite.POSOrder

struct POSOrderBadgeView: View {
    private let order: POSOrder

    init(order: POSOrder) {
        self.order = order
    }

    var body: some View {
        Text(order.status.localizedName)
            .font(.posCaptionRegular)
            .foregroundStyle(statusTextColor)
            .padding(.horizontal, POSPadding.small)
            .padding(.vertical, POSPadding.xSmall)
            .background(statusBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .accessibilityLabel(Localization.badgeAccessibilityLabel(status: order.status.localizedName))
    }

    private var statusTextColor: Color {
        switch order.status {
        case .completed:
            return .posOnInfoLowest
        case .failed:
            return .posOnErrorLowest
        default:
            return .posOnDefault
        }
    }

    private var statusBackgroundColor: Color {
        switch order.status {
        case .completed:
            return .posInfoLowest
        case .failed:
            return .posErrorLowest
        default:
            return .posDefault
        }
    }
}

private extension POSOrderBadgeView {
    enum Localization {
        static func badgeAccessibilityLabel(status: String) -> String {
            let format = NSLocalizedString(
                "pos.orderBadgeView.accessibilityLabel",
                value: "Order status: %1$@",
                comment: "Accessibility label for order status badge. %1$@ is the status name (e.g., Completed, Failed, Processing)."
            )
            return String(format: format, status)
        }
    }
}
