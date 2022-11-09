import SwiftUI
import WidgetKit

/// Entry point for StoreInfo Lock Screen Widget (inline type)
///
struct StoreInfoInlineWidget: View {
    // Entry to render
    let entry: StoreInfoEntry

    var body: some View {
        switch entry {
        case .data(let data):
            StoreInfoInlineView(entryData: data)
        case .notConnected, .error:
            UnableToFetchView()
        }
    }
}

private struct StoreInfoInlineView: View {
    // Stats data to render
    let entryData: StoreInfoData

    var body: some View {
        Text(Localization.titleWithRevenue(entryData.revenue))
            .statValueStyle()
    }
}

private struct UnableToFetchView: View {
    var body: some View {
        Text(Localization.noData)
    }
}

// MARK: - Constants

private extension StoreInfoInlineView {
    enum Localization {
        static func titleWithRevenue(_ revenueString: String) -> LocalizedString {
            let format = AppLocalizedString("storeWidgets.storeInfoInlineWidget.revenueTitle",
                                            value: "Revenue: %1$@",
                                            comment: "Revenue title label for the store info widget. %1$@ is the revenue amount.")
            return LocalizedString.localizedStringWithFormat(format, revenueString)
        }
    }
}

private extension UnableToFetchView {
    enum Localization {
        static let noData = AppLocalizedString(
            "storeWidgets.storeInfoInlineWidget.noData",
            value: "Revenue: ⚠ No Data",
            comment: "Title label when the widget can't fetch data. Should fit in 1 line on lock screen"
        )
    }
}

// MARK: - Previews

@available(iOSApplicationExtension 16.0, *)
struct StoreInfoInlineWidget_Previews: PreviewProvider {
    static var exampleData = StoreInfoData(range: "Today",
                                           name: "Ernest Shop",
                                           revenue: "$132.234",
                                           revenueCompact: "$132",
                                           visitors: "67",
                                           orders: "23",
                                           conversion: "34%",
                                           updatedTime: "10:24 PM")

    static var previews: some View {
        StoreInfoInlineView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .accessoryInline))

        UnableToFetchView()
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Unable to fetch")
    }
}
