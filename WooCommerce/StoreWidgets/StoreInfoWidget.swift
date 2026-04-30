import WidgetKit
import SwiftUI

/// Main StoreInfo Widget type.
///
struct StoreInfoWidget: Widget {
    /// Bundle-level gate for the configurable widget surface. Reads the App Group mirror written
    /// by `StoreWidgetsFeatureFlagSynchronizer` from the local
    /// `FeatureFlag.configurableStoreStatsWidgets`. When enabled, the new home-screen sizes
    /// (`.systemSmall`, `.systemLarge`) are exposed in the widget gallery alongside the existing
    /// `.systemMedium`. Adding sizes is a one-way decision once shipped enabled to App Store.
    ///
    /// `supportedFamilies` is evaluated when iOS launches the widget extension process — not on
    /// every timeline reload — so changes propagate non-deterministically (next extension
    /// relaunch).
    ///
    private var supportedFamilies: [WidgetFamily] {
        /// Temporary developer flag
        /// Will be removed before feature rollout
        let isConfigurableEnabled = UserDefaults.group?.configurableStoreStatsWidgetsEnabled ?? false

        if isConfigurableEnabled {
            return .wooDefaultFamilies + .wooConfigurableFamilies
        }

        return .wooDefaultFamilies
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WooConstants.storeInfoWidgetKind, provider: StoreInfoProvider()) { entry in
            StoreInfoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies(supportedFamilies)
    }
}

/// Widget family constants
private extension Array where Element == WidgetFamily {
    static let wooConfigurableFamilies: [WidgetFamily] = [
        .systemSmall,
        .systemLarge
    ]
    static let wooDefaultFamilies: [WidgetFamily] = [
        .accessoryInline,
        .accessoryRectangular,
        .accessoryCircular,
        .systemMedium
    ]
}

/// Entry view for StoreInfo Widget UI
///
private struct StoreInfoWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: StoreInfoEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            StoreInfoInlineWidget(entry: entry)
        case .accessoryRectangular:
            StoreInfoRectangularWidget(entry: entry)
        case .accessoryCircular:
            StoreInfoCircularWidget(entry: entry)
        case .systemMedium, .systemSmall, .systemLarge:
            // `.systemSmall` and `.systemLarge` only enter `supportedFamilies` when the
            // configurable-widgets FF is on, so reaching them implies the metric-driven path.
            // Layouts dedicated to these sizes will land in Tickets #7 / #8.
            StoreInfoHomescreenWidget(entry: entry)
        default:
            EmptyView()
        }
    }
}

// MARK: Constants

/// Constants definition
///
private extension StoreInfoWidget {
    enum Localization {
        static let title = AppLocalizedString(
            "storeWidgets.displayName",
            value: "Today",
            comment: "Widget title, displayed when selecting which widget to add"
        )
        static let description = AppLocalizedString(
            "storeWidgets.description",
            value: "WooCommerce Stats Today",
            comment: "Widget description, displayed when selecting which widget to add"
        )
    }
}
