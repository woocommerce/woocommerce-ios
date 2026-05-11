import AppIntents
import WidgetKit

/// `AppIntentTimelineProvider` conformance for `StoreInfoProvider`. Kept in a separate file
/// so the data-fetching logic on the main type stays a clean focal point.
///
/// `placeholder(in:)` is satisfied by the conformance on the main type. The snapshot path keeps
/// the same redacted sample data but applies the active AppIntent configuration so gallery
/// previews match the family and default metric slots iOS is presenting.
///
extension StoreInfoProvider: AppIntentTimelineProvider {
    typealias Intent = StoreStatsConfigurationIntent

    func snapshot(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> StoreInfoEntry {
        placeholder(for: configuration, in: context)
    }

    func timeline(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> Timeline<StoreInfoEntry> {
        let metrics = StoreInfoProvider.resolveMetricSelection(
            requested: configuration.metrics,
            family: context.family
        )
        return await loadTimeline(dateRange: configuration.dateRange, metrics: metrics)
    }
}
