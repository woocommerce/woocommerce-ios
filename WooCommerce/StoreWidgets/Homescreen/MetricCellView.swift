import SwiftUI
import WidgetKit

/// Reusable cell that renders a single metric on the home-screen widget.
///
/// Accepts any `MetricPresentable` so the view is testable with stubs and size/family-specific
/// formatting can be swapped by changing the presenter, not the cell. When the metric exposes
/// a `tapURL`, the cell becomes a `Link` so the system handles the deep-link.
///
struct MetricCellView: View {
    let metric: any MetricPresentable

    var body: some View {
        MetricCellLink(destination: metric.tapURL) {
            MetricCellContent(metric: metric, showsChart: true)
        }
    }
}

/// Full-row metric cell used by large widget layouts.
///
/// This keeps the same content treatment as `MetricCellView`; the grid controls
/// the full-row layout by rendering this cell outside the two-column rows.
struct MetricLargeCellView: View {
    let metric: any MetricPresentable

    var body: some View {
        MetricCellLink(destination: metric.tapURL) {
            MetricCellContent(metric: metric)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MetricCellLink<Content: View>: View {
    let destination: URL?
    let content: Content

    init(destination: URL?, @ViewBuilder content: () -> Content) {
        self.destination = destination
        self.content = content()
    }

    var body: some View {
        if let destination {
            Link(destination: destination) {
                content
            }
        } else {
            content
        }
    }
}

private struct MetricCellContent: View {
    let metric: any MetricPresentable
    var showsChart: Bool = false

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack(spacing: Layout.titleRowSpacing) {
                Text(metric.title)
                    .statTitleStyle()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let trend = metric.trend {
                    MetricTrendBadgeView(trend: trend)
                    Spacer()
                }
            }

            ZStack {
                HStack(alignment: .firstTextBaseline, spacing: Layout.valueAndTrendSpacing) {
                    Text(metric.formattedValue)
                        .statValueStyle()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .layoutPriority(1)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsChart, widgetFamily != .systemSmall, let chart = metric.chartData, chart.count > 1 {
                    HStack {
                        Spacer()
                        MetricChartView(data: chart, tone: chartTone)
                            .frame(width: Layout.chartWidth, height: Layout.chartHeight)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chartTone: MetricChartView.Tone {
        switch metric.trend?.direction {
        case .up: return .up
        case .down: return .down
        case nil: return .neutral
        }
    }
}

private extension MetricCellContent {
    enum Layout {
        static let cardSpacing = 2.0
        static let titleRowSpacing = 6.0
        static let valueAndTrendSpacing = 5.0
        static let chartWidth = 70.0
        static let chartHeight = 20.0
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

            MetricLargeCellView(metric: PreviewMetric(title: "Total sales",
                                                      formattedValue: "$12.3k",
                                                      trend: .init(direction: .up, formattedPercentage: "6%")))
                .previewDisplayName("Large cell")
        }
        .frame(width: 180)
        .padding()
        .background(Color(.brand))
        .previewLayout(.sizeThatFits)
    }
}
#endif
