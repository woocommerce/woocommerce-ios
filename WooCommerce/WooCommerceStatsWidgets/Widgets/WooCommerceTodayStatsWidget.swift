import Foundation
import WidgetKit
import SwiftUI

struct WooCommerceTodayStatsWidget: Widget {
    let kind: String = "WooCommerceTodayStatsWidget"
    let placeholderData = StatsWidgetData(revenue: 323.12,
                                          orders: 54,
                                          visitors: 143)

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: StatsProvider(placeholderData: placeholderData, earliestDateToInclude: Date().startOfDay())) { entry in
            WooCommerceStatsWidgetsEntryView(entry: entry, title: Localization.title)
        }
                            .supportedFamilies(FeatureFlagService().widgetsFeatureIsEnabled ? [.systemSmall, .systemMedium] : [])
    }
}

private extension WooCommerceTodayStatsWidget {
    enum Localization {
        static let title = NSLocalizedString("Today", comment: "Title for the Today stats widget in the home screen.")
    }
}
