import WidgetKit
import SwiftUI
import WooFoundation

/// Main StoreInfo Widget type.
///
struct StoreInfoWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WooConstants.storeInfoWidgetKind, provider: StoreInfoProvider()) { entry in
            StoreInfoHomescreenWidget(entry: entry)
        }
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies([.systemMedium])
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
