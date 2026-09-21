import SwiftUI
import WidgetKit

/// Trends Lock Screen widget for the rectangular family.
///
struct StoreTrendsRectangularWidget: View {
    let entry: StoreTrendsEntry

    var body: some View {
        Group {
            switch entry.storeInfoEntry {
            case .data(let data):
                if let metric = data.presentableMetrics.first {
                    StoreTrendsRectangularView(
                        metric: metric,
                        compactRange: entry.compactRange
                    )
                } else {
                    // The Trends provider resolves exactly one metric for `.accessoryRectangular`.
                    // Keep this fallback so malformed preview/provider data renders instead of crashing.
                    StoreTrendsRectangularUnavailableView(
                        metricTitle: entry.unavailableMetricTitle,
                        compactRange: entry.compactRange
                    )
                }
            case .notConnected, .error:
                StoreTrendsRectangularUnavailableView(
                    metricTitle: entry.unavailableMetricTitle,
                    compactRange: entry.compactRange
                )
            }
        }
        .widgetBackground(backgroundView: AccessoryWidgetBackground())
        .dynamicTypeSize(.xSmall...StoreInfoDynamicType.maximumSize)
    }
}

private struct StoreTrendsRectangularView: View {
    let metric: any MetricPresentable
    let compactRange: String

    var body: some View {
        MetricCellLink(destination: metric.tapURL) {
            VStack(alignment: .leading, spacing: StoreTrendsRectangularLayout.verticalSpacing) {
                StoreTrendsRectangularHeader(title: metric.title, range: compactRange)

                chart

                HStack(alignment: .firstTextBaseline, spacing: StoreTrendsRectangularLayout.horizontalSpacing) {
                    Text(metric.formattedValue)
                        .layoutPriority(1)
                        .statTrendTextStyle()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: StoreTrendsRectangularLayout.horizontalSpacing)

                    if let trend = metric.trend {
                        MetricTrendBadgeView(trend: trend, size: .regular, style: .onPrimary)
                    }
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var chart: some View {
        if let chartData = metric.chartData, chartData.count > 1 {
            MetricChartView(data: chartData, style: .barOnPrimary)
                .frame(height: StoreTrendsRectangularLayout.chartHeight)
        } else {
            MetricChartReferenceLines()
                .accessibilityHidden(true)
                .frame(height: StoreTrendsRectangularLayout.chartHeight)
        }
    }
}

private struct StoreTrendsRectangularUnavailableView: View {
    let metricTitle: String
    let compactRange: String

    var body: some View {
        VStack(alignment: .leading, spacing: StoreTrendsRectangularLayout.verticalSpacing) {
            StoreTrendsRectangularHeader(
                title: metricTitle,
                range: compactRange,
                style: .unavailable
            )

            MetricChartReferenceLines()
                .accessibilityHidden(true)
                .frame(height: StoreTrendsRectangularLayout.chartHeight)

            Text(Localization.noData)
                .font(.title3.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private enum StoreTrendsRectangularLayout {
    static let verticalSpacing = 0.0
    static let horizontalSpacing = 6.0
    static let chartHeight = 15.0
}

private struct StoreTrendsRectangularHeader: View {
    let title: String
    let range: String
    let style: Style

    init(title: String, range: String, style: Style = .metric) {
        self.title = title
        self.range = range
        self.style = style
    }

    var body: some View {
        HStack(alignment: .top, spacing: StoreTrendsRectangularLayout.horizontalSpacing) {
            Image("woo-mini-logo", bundle: nil)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
                .padding(.top, -2)
                .accessibilityHidden(true)

            titleText
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)

            Spacer(minLength: StoreTrendsRectangularLayout.horizontalSpacing)

            rangeText
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

private extension StoreTrendsRectangularHeader {
    enum Style {
        case metric
        case unavailable
    }

    @ViewBuilder
    var titleText: some View {
        switch style {
        case .metric:
            Text(title)
                .storeNameStyle()
        case .unavailable:
            Text(title)
                .font(.headline.weight(.semibold))
        }
    }

    @ViewBuilder
    var rangeText: some View {
        switch style {
        case .metric:
            Text(range)
                .statRangeStyle()
        case .unavailable:
            Text(range)
                .font(.headline.weight(.semibold))
        }
    }
}

private extension StoreTrendsRectangularUnavailableView {
    enum Localization {
        static let noData = AppLocalizedString(
            "storeWidgets.trendsRectangularWidget.noData",
            value: "No data",
            comment: "Label when the Trends rectangular lock-screen widget cannot fetch data."
        )
    }
}

#if DEBUG
struct StoreTrendsRectangularWidget_Previews: PreviewProvider {
    private static var sampleData: StoreInfoData {
        StoreInfoMetricsView_Previews.fullCatalogData
    }

    static var previews: some View {
        StoreTrendsRectangularView(
            metric: WidgetMetricPresenter(metric: sampleData.metrics[0], dateRange: .lastWeek),
            compactRange: StoreStatsWidgetDateRange.lastWeek.localizedCompactRangeLabel
        )
        .widgetBackground(backgroundView: Color.clear)
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        .previewDisplayName("Revenue")

        StoreTrendsRectangularView(
            metric: WidgetMetricPresenter(metric: sampleData.metrics[1], dateRange: .lastWeek),
            compactRange: StoreStatsWidgetDateRange.lastWeek.localizedCompactRangeLabel
        )
        .widgetBackground(backgroundView: AccessoryWidgetBackground())
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        .previewDisplayName("Orders")

        StoreTrendsRectangularUnavailableView(
            metricTitle: StoreInfoMetricType.orders.displayName,
            compactRange: StoreStatsWidgetDateRange.lastMonth.localizedCompactRangeLabel
        )
            .widgetBackground(backgroundView: AccessoryWidgetBackground())
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Unavailable")
    }
}
#endif
