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
                if let metric = data.metrics.first {
                    StoreTrendsRectangularView(
                        metric: metric,
                        compactRange: data.rangeCompact
                    )
                } else {
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
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: Layout.horizontalSpacing) {
                    Text(metric.title)
                        .storeNameStyle()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .layoutPriority(1)

                    Spacer(minLength: Layout.horizontalSpacing)

                    Text(compactRange)
                        .statRangeStyle()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                chart

                HStack(alignment: .firstTextBaseline, spacing: Layout.horizontalSpacing) {
                    Text(metric.formattedValue)
                        .layoutPriority(1)
                        .statTrendTextStyle()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: Layout.horizontalSpacing)

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
                .frame(height: Layout.chartHeight)
        } else {
            RectangularMetricChartPlaceholderView()
                .frame(height: Layout.chartHeight)
        }
    }

    private enum Layout {
        static let verticalSpacing = 2.0
        static let horizontalSpacing = 6.0
        static let chartHeight = 15.0
    }
}

private struct StoreTrendsRectangularUnavailableView: View {
    let metricTitle: String
    let compactRange: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: Layout.horizontalSpacing) {
                Text(metricTitle)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: Layout.horizontalSpacing)

                Text(compactRange)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            RectangularMetricChartPlaceholderView()
                .frame(height: Layout.chartHeight)

            Text(Localization.noData)
                .font(.title3.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private enum Layout {
        static let verticalSpacing = 2.0
        static let horizontalSpacing = 6.0
        static let chartHeight = 15.0
    }
}

private struct RectangularMetricChartPlaceholderView: View {
    var body: some View {
        MetricChartReferenceLines()
            .accessibilityHidden(true)
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
            metric: sampleData.metrics[0],
            compactRange: StoreStatsWidgetDateRange.last30Days.localizedCompactRangeLabel
        )
        .widgetBackground(backgroundView: Color.clear)
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        .previewDisplayName("Revenue")

        StoreTrendsRectangularView(
            metric: sampleData.metrics[1],
            compactRange: StoreStatsWidgetDateRange.last7Days.localizedCompactRangeLabel
        )
        .widgetBackground(backgroundView: AccessoryWidgetBackground())
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        .previewDisplayName("Orders")

        StoreTrendsRectangularUnavailableView(
            metricTitle: StoreInfoMetricType.orders.displayName,
            compactRange: StoreStatsWidgetDateRange.last30Days.localizedCompactRangeLabel
        )
            .widgetBackground(backgroundView: AccessoryWidgetBackground())
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Unavailable")
    }
}
#endif
