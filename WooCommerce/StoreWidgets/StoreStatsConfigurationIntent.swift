import AppIntents
import WidgetKit

/// Configuration intent for the Store Stats widget.
///
/// Currently has no parameters — its sole purpose is to switch `StoreInfoWidget` from
/// `StaticConfiguration` to `AppIntentConfiguration` so the widget extension is on the
/// modern API. Subsequent tickets add `@Parameter` declarations (date range, metrics,
/// store picker) on top of this scaffold.
///
struct StoreStatsConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Store Stats"
    static var description = IntentDescription("Choose how the WooCommerce stats widget is displayed.")
}
