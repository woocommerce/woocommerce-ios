import SwiftUI
import WidgetKit

/// Configurable Store Stats widget for compact trend-focused lock-screen surfaces.
///
struct StoreTrendsWidget: Widget {
    private var supportedFamilies: [WidgetFamily] {
        guard UserDefaults.group?.configurableStoreStatsWidgetsEnabled == true else {
            return []
        }
        return [.accessoryRectangular]
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WooConstants.storeTrendsWidgetKind,
            intent: StoreStatsConfigurationIntent.self,
            provider: StoreInfoProvider()
        ) { entry in
            StoreTrendsRectangularWidget(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies(supportedFamilies)
    }
}

private extension StoreTrendsWidget {
    enum Localization {
        static let title = AppLocalizedString(
            "storeWidgets.trends.displayName",
            value: "Trends",
            comment: "Widget title, displayed when selecting the configurable Store Stats trends widget."
        )
        static let description = AppLocalizedString(
            "storeWidgets.trends.description",
            value: "Track store trends on your lock screen.",
            comment: "Widget description, displayed when selecting the configurable Store Stats trends widget."
        )
    }
}
