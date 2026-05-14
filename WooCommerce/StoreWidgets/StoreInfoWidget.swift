import WidgetKit
import SwiftUI

/// Main StoreInfo Widget type.
///
struct StoreInfoWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WooConstants.storeInfoWidgetKind,
            intent: StoreStatsConfigurationIntent.self,
            provider: StoreInfoProvider()
        ) { entry in
            StoreInfoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies([
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular,
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
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
            StoreInfoHomescreenWidget(entry: entry)
                .applyingStoreWidgetTheme(theme(for: entry))
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
