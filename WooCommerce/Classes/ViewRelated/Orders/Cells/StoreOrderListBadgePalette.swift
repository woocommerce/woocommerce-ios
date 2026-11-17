import StoreDesignSystem
import SwiftUI
import Yosemite

enum StoreOrderListBadgePalette {
    static func statusTone(for status: OrderStatusEnum) -> StoreBadgeTone {
        .custom(background: statusBackground(for: status), foreground: .storePaletteBlack)
    }

    static func statusBackground(for status: OrderStatusEnum) -> Color {
        Color(uiColor: status.backgroundColor)
    }

    static let pointOfSaleTone = StoreBadgeTone.custom(
        background: .storePrimaryContainer,
        foreground: .storeOnPrimaryContainer
    )
}
