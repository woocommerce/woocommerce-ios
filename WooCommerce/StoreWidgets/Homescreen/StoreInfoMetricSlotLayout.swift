import SwiftUI
import WidgetKit

enum StoreInfoMetricSlotLayout {
    enum Family {
        case small
        case medium
        case large

        var defaultLimit: Int {
            StoreStatsConfigurationIntent.metricsSlotCounts[widgetFamily]!
        }

        private var widgetFamily: WidgetFamily {
            switch self {
            case .small:
                return .systemSmall
            case .medium:
                return .systemMedium
            case .large:
                return .systemLarge
            }
        }

        var accessibilityLimit: Int {
            switch self {
            case .small:
                return 1
            case .medium:
                return defaultLimit
            case .large:
                return 4
            }
        }
    }

    static func visibleSlots(
        from slots: [StoreInfoMetricSlot],
        family: Family,
        dynamicTypeSize: DynamicTypeSize
    ) -> [StoreInfoMetricSlot] {
        let limit = usesAccessibilityLayout(dynamicTypeSize: dynamicTypeSize) ? family.accessibilityLimit : family.defaultLimit
        return Array(slots.prefix(limit))
    }

    static func usesAccessibilityLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        StoreInfoDynamicType.usesAccessibilityLayout(dynamicTypeSize)
    }
}
