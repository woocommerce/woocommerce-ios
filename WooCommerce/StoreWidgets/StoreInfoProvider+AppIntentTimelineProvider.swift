import AppIntents
import WidgetKit

/// `AppIntentTimelineProvider` conformance for `StoreInfoProvider`. Kept in a separate file
/// so the data-fetching logic on the main type stays a clean focal point.
///
/// `placeholder(in:)` is satisfied by the conformance on the main type — both the snapshot
/// path here and the gallery placeholder share the same redacted sample entry.
///
extension StoreInfoProvider: AppIntentTimelineProvider {
    typealias Intent = StoreStatsConfigurationIntent

    func snapshot(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> StoreInfoEntry {
        placeholder(in: context)
    }

    func timeline(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> Timeline<StoreInfoEntry> {
        await loadTimeline(dateRange: configuration.dateRange)
    }
}
