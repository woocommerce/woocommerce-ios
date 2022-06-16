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
                            provider: StatsWidgetsTimelineProvider(placeholderData: placeholderData, earliestDateToInclude: Date().startOfWeek())) { entry in
            WooCommerceStatsWidgetsEntryView(entry: entry, title: Localization.title)
        }
                            .supportedFamilies(FeatureFlagService().widgetsFeatureIsEnabled ? [.systemSmall, .systemMedium] : [])
    }
}

private extension WooCommerceThisWeekStatsWidget {
    enum Localization {
        static let title = NSLocalizedString("This Week", comment: "Title for the weekly stats widget in the home screen.")
    }
}
