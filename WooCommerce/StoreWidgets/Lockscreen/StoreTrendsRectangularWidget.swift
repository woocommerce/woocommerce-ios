import Charts
import SwiftUI
import WidgetKit

/// Trends Lock Screen widget for the rectangular family.
///
struct StoreTrendsRectangularWidget: View {
    let entry: StoreInfoEntry

    var body: some View {
        Group {
            switch entry {
            case .data(let data):
                if let metric = data.metrics.first {
                    StoreTrendsRectangularView(
                        metric: metric,
                        compactRange: data.rangeCompact
                    )
                } else {
                    StoreTrendsRectangularUnavailableView()
                }
            case .notConnected, .error:
                StoreTrendsRectangularUnavailableView()
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
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .layoutPriority(1)

                    Spacer(minLength: Layout.horizontalSpacing)

                    Text(compactRange)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                chart

                HStack(alignment: .firstTextBaseline, spacing: Layout.horizontalSpacing) {
                    Text(metric.formattedValue)
                        .font(.title3.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .layoutPriority(1)

                    Spacer(minLength: Layout.horizontalSpacing)

                    if let trend = metric.trend {
                        RectangularMetricTrendView(trend: trend)
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
            RectangularMetricChartView(data: chartData)
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
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: Layout.horizontalSpacing) {
                Text(Localization.revenue)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: Layout.horizontalSpacing)

                Text(StoreStatsWidgetDateRange.today.localizedCompactRangeLabel)
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

private struct RectangularMetricChartView: View {
    let data: [MetricChartPoint]

    var body: some View {
        GeometryReader { proxy in
            Chart(Array(data.enumerated()), id: \.offset) { index, point in
                BarMark(
                    x: .value("Interval", String(index)),
                    y: .value("Value", max(point.value, barMinHeight)),
                    width: .ratio(Constants.barWidthRatio)
                )
                .foregroundStyle(barColor(for: point))
                .cornerRadius(barCornerRadius(chartWidth: proxy.size.width))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...yDomainMax)
            .chartPlotStyle { plot in
                plot
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RectangularMetricChartReferenceLines())
            }
            .accessibilityHidden(true)
        }
    }
}

private extension RectangularMetricChartView {
    var maxValue: Double {
        data.map(\.value).max() ?? 0
    }

    var yDomainMax: Double {
        max(maxValue, Constants.minYDomainCeiling)
    }

    var barMinHeight: Double {
        yDomainMax * Constants.barMinHeightRatio
    }

    func barColor(for point: MetricChartPoint) -> Color {
        point.value <= 0 ? Color.primary.opacity(Constants.zeroBarOpacity) : Color.primary.opacity(Constants.barOpacity)
    }

    func barCornerRadius(chartWidth: Double) -> Double {
        guard !data.isEmpty, chartWidth > 0 else { return 0 }
        let barWidth = chartWidth / Double(data.count) * Constants.barWidthRatio
        return barWidth / 2
    }

    enum Constants {
        static let barWidthRatio = 0.65
        static let barMinHeightRatio = 0.04
        static let barOpacity = 0.78
        static let zeroBarOpacity = 0.32
        static let minYDomainCeiling = 1.0
    }
}

private struct RectangularMetricChartPlaceholderView: View {
    var body: some View {
        RectangularMetricChartReferenceLines()
            .accessibilityHidden(true)
    }
}

private struct RectangularMetricChartReferenceLines: View {
    var body: some View {
        VStack(spacing: 0) {
            line(opacity: 0.18)
            Spacer(minLength: 0)
            line(opacity: 0.16)
            Spacer(minLength: 0)
            line(opacity: 0.28)
        }
    }

    private func line(opacity: Double) -> some View {
        Rectangle()
            .fill(Color.primary.opacity(opacity))
            .frame(height: 1)
    }
}

private struct RectangularMetricTrendView: View {
    let trend: MetricTrendPresentation

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Image(systemName: symbolName)
                .font(.caption.weight(.bold))
                .accessibilityHidden(true)

            if trend.direction != .flat {
                Text(trend.formattedPercentage)
                    .font(.title3.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .foregroundStyle(.primary.opacity(0.82))
    }
}

private extension RectangularMetricTrendView {
    var symbolName: String {
        switch trend.direction {
        case .up:
            return "chevron.up"
        case .down:
            return "chevron.down"
        case .flat:
            return "minus"
        }
    }

    enum Layout {
        static let spacing = 4.0
    }
}

private extension StoreTrendsRectangularUnavailableView {
    enum Localization {
        static let revenue = AppLocalizedString(
            "storeWidgets.trendsRectangularWidget.totalSales",
            value: "Total sales",
            comment: "Default metric title for the Trends rectangular lock-screen widget."
        )
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
        Group {
            StoreTrendsRectangularView(
                metric: sampleData.metrics[0],
                compactRange: StoreStatsWidgetDateRange.last7Days.localizedCompactRangeLabel
            )
            .previewDisplayName("Revenue")

            StoreTrendsRectangularView(
                metric: sampleData.metrics[1],
                compactRange: StoreStatsWidgetDateRange.last7Days.localizedCompactRangeLabel
            )
            .previewDisplayName("Orders")

            StoreTrendsRectangularUnavailableView()
                .previewDisplayName("Unavailable")
        }
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
#endif
