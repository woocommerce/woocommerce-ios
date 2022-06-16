import Foundation
import WidgetKit
import SwiftUI

struct WooCommerceThisWeekStatsWidget: Widget {
    let kind: String = "WooCommerceThisWeekStatsWidget"
    let placeholderData = StatsWidgetData(revenue: 1349.21,
                                          orders: 154,
                                          visitors: 686)

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: StatsProvider(placeholderData: placeholderData, earliestDateToInclude: Date().startOfWeek())) { entry in
            WooCommerceStatsWidgetsEntryView(entry: entry, title: "This Week")
        }
                            .supportedFamilies(FeatureFlagService().widgetsFeatureIsEnabled ? [.systemSmall, .systemMedium] : [])
    }
}
