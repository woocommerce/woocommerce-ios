import SwiftUI
import WidgetKit

/// Entry point for StoreInfo Lock Screen Widget (rectangular type)
///
struct StoreInfoRectangularWidget: View {
    // Entry to render
    let entry: StoreInfoEntry

    var body: some View {
        Group {
            switch entry {
            case .data(let data):
                StoreInfoRectangularView(entryData: data)
            case .notConnected, .error:
                UnableToFetchView()
            }
        }
        .widgetBackground(backgroundView: Color(.clear))
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
                Text(entryData.revenueCompact)
            }
            Spacer()
        }
        .widgetBackground(backgroundView: Color(.brand))
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
            "storeWidgets.storeInfoRectangularWidget.netSales",
            value: "Net sales",
            comment: "Net sales title label for the store info widget — shows revenue excluding taxes, shipping, and fees."
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
#if DEBUG
import class WooFoundation.CurrencySettings

@available(iOSApplicationExtension 16.0, *)
struct StoreInfoRectangularWidget_Previews: PreviewProvider {
    static var exampleData = StoreInfoData(range: "Today",
                                           name: "Ernest Shop",
                                           revenue: StoreInfoFormatter.formattedAmountString(for: Decimal(123456789), with: CurrencySettings()),
                                           revenueCompact: StoreInfoFormatter.formattedAmountCompactString(for: Decimal(123456789), with: CurrencySettings()),
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
#endif
