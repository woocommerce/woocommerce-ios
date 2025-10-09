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
            return Color(uiColor: .init(red: 10/255, green: 17/255, blue: 45/255, alpha: 1))
        case .failed:
            return Color(uiColor: .init(red: 36/255, green: 10/255, blue: 10/255, alpha: 1))
        default:
            return Color(uiColor: .init(red: 16/255, green: 21/255, blue: 23/255, alpha: 1))
        }
    }

    private var statusBackgroundColor: Color {
        switch order.status {
        case .completed:
            return Color(uiColor: .init(red: 214/255, green: 221/255, blue: 249/255, alpha: 1))
        case .failed:
            return Color(uiColor: .init(red: 247/255, green: 235/255, blue: 236/255, alpha: 1))
        default:
            return Color(uiColor: .init(red: 220/255, green: 220/255, blue: 222/255, alpha: 1))
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
