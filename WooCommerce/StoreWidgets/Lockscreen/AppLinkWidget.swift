import WidgetKit
import SwiftUI

/// Static widget - app launch button
///
struct AppLinkWidget: Widget {
    private var supportedFamilies: [WidgetFamily] {
#if !os(watchOS)
        if #available(iOSApplicationExtension 16.0, *) {
            return [.accessoryCircular]
        } else {
            return []
        }
#else
        return [.accessoryCorner, .accessoryCircular]
#endif
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WooConstants.appLinkWidgetKind, provider: AppLinkProvider()) { _ in
            AppButtonView()
        }
        .containerBackgroundRemovable(false)
        .configurationDisplayName(Localization.title)
        .description(Localization.description)
        .supportedFamilies(supportedFamilies)
    }
}

private struct AppLinkProvider: TimelineProvider {
    /// Type that represents the all the possible Widget states
    ///
    enum AppLinkEntry: TimelineEntry {
        // Single possible state
        case appLink

        // Current date, needed by the `TimelineEntry` protocol.
        var date: Date { Date() }
    }

    func placeholder(in context: Context) -> AppLinkEntry {
        return .appLink
    }

    func getSnapshot(in context: Context, completion: @escaping (AppLinkEntry) -> Void) {
        completion(.appLink)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AppLinkEntry>) -> Void) {
        let timeline = Timeline<AppLinkEntry>(entries: [.appLink], policy: .never)
        completion(timeline)
    }
}

private struct AppButtonView: View {

    private var logoAssetName: String {
#if os(watchOS)
        "woo-mini-logo"
#else
        "woo-logo"
#endif
    }

    private var background: some View {
#if os(watchOS)
        EmptyView()
#else
        AccessoryWidgetBackground()
#endif
    }

    var body: some View {
        Image(logoAssetName, bundle: nil)
            .resizable()
            .scaledToFit()
            .padding(8)
            .widgetBackground(backgroundView: background)
    }
}

// MARK: Constants

/// Constants definition
///
private extension AppLinkWidget {
    enum Localization {
        static let title = AppLocalizedString(
            "appLinkWidget.displayName",
            value: "Icon",
            comment: "Widget title, displayed when selecting which widget to add"
        )
        static let description = AppLocalizedString(
            "appLinkWidget.description",
            value: "Quickly Launch WooCommerce",
            comment: "Widget description, displayed when selecting which widget to add"
        )
    }
}

// MARK: Previews

@available(iOSApplicationExtension 16.0, *)
struct AppLinkWidget_Previews: PreviewProvider {
    static var previews: some View {
        AppButtonView()
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
