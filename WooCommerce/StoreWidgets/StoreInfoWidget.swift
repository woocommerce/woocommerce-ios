import WidgetKit
import SwiftUI

/// Main StoreInfo Widget type.
///
struct StoreInfoWidget: Widget {
    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [
                .accessoryInline,
                .accessoryRectangular,
                .accessoryCircular,
                .systemMedium
            ]
        } else {
            return [.systemMedium]
        }
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

/// Entry view for StoreInfo Widget UI
///
private struct StoreInfoWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: StoreInfoEntry

    var body: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            switch widgetFamily {
            case .accessoryInline:
                StoreInfoInlineWidget(entry: entry)
            case .accessoryRectangular:
                StoreInfoRectangularWidget(entry: entry)
            case .accessoryCircular:
                StoreInfoCircularWidget(entry: entry)
            case .systemMedium:
                StoreInfoHomescreenWidget(entry: entry)
            default:
                EmptyView()
            }
        } else {
            StoreInfoHomescreenWidget(entry: entry)
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
