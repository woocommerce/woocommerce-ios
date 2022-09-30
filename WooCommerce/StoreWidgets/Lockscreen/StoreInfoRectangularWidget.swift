import SwiftUI
import WidgetKit

/// Entry point for StoreInfo Lock Screen Widget (rectangular type)
///
struct StoreInfoRectangularWidget: View {
    // Entry to render
    let entry: StoreInfoEntry

    var body: some View {
        switch entry {
        case .data(let data):
            StoreInfoRectangularView(entryData: data)
        case .notConnected, .error:
            UnableToFetchView()
        }
    }
}

private struct StoreInfoRectangularView: View {
    // Stats data to render
    let entryData: StoreInfoData

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Localization.revenue)
                    .font(.headline)
                Text(entryData.revenue)
            }
            Spacer()
        }
    }
}

private struct UnableToFetchView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(StoreInfoRectangularView.Localization.revenue)
                    .font(.headline)
                Text(Localization.noData)
            }
            Spacer()
        }
    }
}

// MARK: - Constants

private extension StoreInfoRectangularView {
    enum Localization {
        static let revenue = AppLocalizedString(
            "storeWidgets.storeInfoRectangularWidget.revenue",
            value: "Revenue",
            comment: "Revenue title label for the store info widget"
        )
    }
}

private extension UnableToFetchView {
    enum Localization {
        static let noData = AppLocalizedString(
            "storeWidgets.storeInfoRectangularWidget.noData",
            value: "⚠ No Data",
            comment: "Label when the widget can't fetch data."
        )
    }
}

// MARK: - Previews

@available(iOSApplicationExtension 16.0, *)
struct StoreInfoRectangularWidget_Previews: PreviewProvider {
    static var exampleData = StoreInfoData(range: "Today",
                                           name: "Ernest Shop",
                                           revenue: "$132.234",
                                           revenueCompact: "$132",
                                           visitors: "67",
                                           orders: "23",
                                           conversion: "34%",
                                           updatedTime: "10:24 PM")

    static var previews: some View {
        StoreInfoRectangularView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        UnableToFetchView()
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Unable to fetch")
    }
}
