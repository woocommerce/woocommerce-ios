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
        // Compile-time gate on the configuration type — matches the runtime
        // `configurableStoreStatsWidgets` FF policy (localDeveloper || alpha) at the build
        // level. A runtime gate is not expressible: `Widget.body` is `some WidgetConfiguration`
        // (opaque return — branches must agree on a single concrete type) and
        // `WidgetBundleBuilder` explicitly disables `buildOptional` for runtime `if`. The
        // configuration `kind` is identical across both branches, so existing tiles survive
        // the compile-time switch when alpha builds upgrade to App Store builds and back.
#if DEBUG || ALPHA
        AppIntentConfiguration(
            kind: WooConstants.storeInfoWidgetKind,
            intent: StoreStatsConfigurationIntent.self,
            provider: StoreInfoProvider()
        ) { entry in
            StoreInfoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies(supportedFamilies)
#else
        StaticConfiguration(
            kind: WooConstants.storeInfoWidgetKind,
            provider: StoreInfoProvider()
        ) { entry in
            StoreInfoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies(supportedFamilies)
#endif
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
            // Family-specific layouts are still pending; for now all three render via
            // `StoreInfoHomescreenWidget`'s shared body.
            StoreInfoHomescreenWidget(entry: entry)
                .environment(\.storeWidgetTheme, theme(for: entry))
        default:
            EmptyView()
        }
    }

    /// Theme to apply to the home-screen widget body. Carried on `StoreInfoData`; error and
    /// not-connected entries fall back to `.brandPurple`.
    private func theme(for entry: StoreInfoEntry) -> StoreWidgetTheme {
        switch entry {
        case .data(let data): return data.theme
        case .notConnected, .error: return .brandPurple
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
