import AppIntents
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
            provider: StoreTrendsProvider()
        ) { entry in
            StoreTrendsRectangularWidget(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies(supportedFamilies)
    }
}

struct StoreTrendsEntry: TimelineEntry {
    let date: Date
    let storeInfoEntry: StoreInfoEntry
    let unavailableMetricTitle: String
    let compactRange: String

    init(date: Date = Date(),
         storeInfoEntry: StoreInfoEntry,
         dateRange: StoreStatsWidgetDateRange,
         metrics visibleMetrics: [StoreInfoMetricType]) {
        self.date = date
        self.storeInfoEntry = storeInfoEntry
        self.unavailableMetricTitle = visibleMetrics.first?.displayName ?? StoreInfoMetricType.revenue.displayName
        self.compactRange = dateRange.localizedCompactRangeLabel
    }
}

private struct StoreTrendsProvider: AppIntentTimelineProvider {
    typealias Intent = StoreStatsConfigurationIntent

    private let storeInfoProvider = StoreInfoProvider()

    func placeholder(in context: Context) -> StoreTrendsEntry {
        let metrics = StoreStatsConfigurationIntent.resolveMetricSelection(
            requested: StoreStatsConfigurationIntent.defaultMetrics,
            family: .accessoryRectangular
        )
        return StoreTrendsEntry(
            storeInfoEntry: StoreInfoProvider.placeholderEntry(metrics: metrics),
            dateRange: StoreStatsConfigurationIntent.defaultDateRange,
            metrics: metrics
        )
    }

    func snapshot(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> StoreTrendsEntry {
        let metrics = resolvedMetrics(for: configuration)
        return StoreTrendsEntry(
            storeInfoEntry: StoreInfoProvider.placeholderEntry(dateRange: configuration.dateRange, metrics: metrics),
            dateRange: configuration.dateRange,
            metrics: metrics
        )
    }

    func timeline(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> Timeline<StoreTrendsEntry> {
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

    private func resolvedMetrics(for configuration: StoreStatsConfigurationIntent) -> [StoreInfoMetricType] {
        StoreStatsConfigurationIntent.resolveMetricSelection(
            requested: configuration.metrics,
            family: .accessoryRectangular
        )
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
