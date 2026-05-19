import AppIntents
import SwiftUI
import WidgetKit

/// Configurable Store Stats widget for compact trend-focused lock-screen surfaces.
///
struct StoreTrendsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WooConstants.storeTrendsWidgetKind,
            intent: StoreTrendsConfigurationIntent.self,
            provider: StoreTrendsProvider()
        ) { entry in
            StoreTrendsRectangularWidget(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies([.accessoryRectangular])
    }
}

private struct StoreTrendsProvider: AppIntentTimelineProvider {
    typealias Intent = StoreTrendsConfigurationIntent

    private let storeInfoProvider = StoreInfoProvider()

    func placeholder(in context: Context) -> StoreTrendsEntry {
        let metrics = StoreTrendsConfigurationIntent.resolveMetricSelection(
            requested: StoreTrendsConfigurationIntent.defaultMetrics
        )
        return StoreTrendsEntry(
            storeInfoEntry: StoreInfoProvider.placeholderEntry(metrics: metrics),
            dateRange: StoreTrendsConfigurationIntent.defaultDateRange,
            metrics: metrics
        )
    }

    func snapshot(for configuration: StoreTrendsConfigurationIntent, in context: Context) async -> StoreTrendsEntry {
        let metrics = resolvedMetrics(for: configuration)
        return StoreTrendsEntry(
            storeInfoEntry: StoreInfoProvider.placeholderEntry(dateRange: configuration.dateRange, metrics: metrics),
            dateRange: configuration.dateRange,
            metrics: metrics
        )
    }

    func timeline(for configuration: StoreTrendsConfigurationIntent, in context: Context) async -> Timeline<StoreTrendsEntry> {
        let metrics = resolvedMetrics(for: configuration)
        let timeline = await storeInfoProvider.loadTimeline(dateRange: configuration.dateRange,
                                                            metrics: metrics,
                                                            selectedStoreID: configuration.store?.id)
        return Timeline(
            entries: timeline.entries.map { entry in
                StoreTrendsEntry(
                    date: entry.date,
                    storeInfoEntry: entry,
                    dateRange: configuration.dateRange,
                    metrics: metrics
                )
            },
            policy: timeline.policy
        )
    }

    private func resolvedMetrics(for configuration: StoreTrendsConfigurationIntent) -> [StoreInfoMetricType] {
        StoreTrendsConfigurationIntent.resolveMetricSelection(requested: configuration.metrics)
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
