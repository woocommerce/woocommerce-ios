import SwiftUI
import WidgetKit

/// Compact metric cell used in the 2-column grid of medium and large widgets.
///
/// Owns a sparkline overlay anchored to the bottom-trailing of the cell, gated to
/// non-small widget families.
///
struct MetricCellView: View {
    let metric: any MetricPresentable

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        MetricCellLink(destination: metric.tapURL) {
            ZStack(alignment: .bottomTrailing) {
                MetricCellTextStack(
                    metric: metric,
                    trendPlacement: .alongsideTitle,
                    size: .regular
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                if widgetFamily != .systemSmall, let chart = metric.chartData, chart.count > 1 {
                    MetricChartView(data: chart, tone: chartTone)
                        .frame(width: Layout.chartWidth, height: Layout.chartHeight)
                }
            }
        }
    }
}

private extension MetricCellView {
    var chartTone: MetricChartView.Tone {
        switch metric.trend?.direction {
        case .up: return .up
        case .down: return .down
        case nil: return .neutral
        }
    }

    enum Layout {
        static let chartWidth = 70.0
        static let chartHeight = 16.0
    }
}

// MARK: - Previews
#if DEBUG
struct MetricCellView_Previews: PreviewProvider {
    private struct PreviewMetric: MetricPresentable {
        let title: String
        let formattedValue: String
        var trend: MetricTrendPresentation?
        var chartData: [MetricChartPoint]?
    }

    private static var sampleChart: [MetricChartPoint] {
        let now = Date()
        return (0..<24).map { hour in
            let date = now.addingTimeInterval(TimeInterval(-hour * 3600))
            // Plausible-looking hourly pattern: midday peak.
            let value = Double.random(in: 0...10) + max(0, 12 - Double(abs(12 - hour)))
            return MetricChartPoint(date: date, value: value)
        }.reversed()
    }

    static var previews: some View {
        Group {
            MetricCellView(metric: PreviewMetric(title: "Total sales", formattedValue: "$12.3k"))
                .previewDisplayName("Without trend")

            MetricCellView(metric: PreviewMetric(title: "Total sales",
                                                 formattedValue: "$12.3k",
                                                 trend: .init(direction: .up, formattedPercentage: "6%"),
                                                 chartData: sampleChart))
                .previewDisplayName("With trend up + chart")

            MetricCellView(metric: PreviewMetric(title: "Total sales",
                                                 formattedValue: "$12.3k",
                                                 trend: .init(direction: .down, formattedPercentage: "12%"),
                                                 chartData: sampleChart))
                .previewDisplayName("With trend down + chart")
        }
        .frame(width: 180)
        .padding()
        .background(Color(.brand))
        .previewLayout(.sizeThatFits)
    }
}
#endif
