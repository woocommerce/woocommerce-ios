import AppIntents
import WidgetKit

/// `AppIntentTimelineProvider` conformance for `StoreInfoProvider`. Kept in a separate file
/// so the legacy `TimelineProvider` path stays a clean focal point and so this conformance
/// can be removed in a single edit once the configurable widget rollout completes and the
/// `StaticConfiguration` path retires.
///
/// `placeholder(in:)` is satisfied by the conformance on the main type — both protocols
/// use the same signature.
///
extension StoreInfoProvider: AppIntentTimelineProvider {
    typealias Intent = StoreStatsConfigurationIntent

    func snapshot(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> StoreInfoEntry {
        placeholder(in: context)
    }

    func timeline(for configuration: StoreStatsConfigurationIntent, in context: Context) async -> Timeline<StoreInfoEntry> {
        await loadTimeline()
    }
}
