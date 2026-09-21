import SwiftUI

/// Full-row metric cell rendered as the leading row of the large widget.
///
/// Stacks vertically: the text stack sits above a bar chart that fills the
/// remaining width and height of the cell.
///
struct MetricLargeCellView: View {
    let metric: any MetricPresentable

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        MetricCellLink(destination: metric.tapURL) {
            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                MetricCellTextStack(
                    metric: metric,
                    trendPlacement: .alongsideValue,
                    size: .large
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsChart, let chart = metric.chartData, chart.count > 1 {
                    MetricChartView(
                        data: chart,
                        style: .bar,
                        tone: chartTone
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private extension MetricLargeCellView {
    var showsChart: Bool {
        !StoreInfoDynamicType.usesAccessibilityLayout(dynamicTypeSize)
    }

    var chartTone: MetricChartView.Tone {
        switch metric.trend?.direction {
        case .up: return .up
        case .down: return .down
        case .flat, nil: return .neutral
        }
    }

    enum Layout {
        static let contentSpacing = 12.0
    }
}

// MARK: - Previews
#if DEBUG
struct MetricLargeCellView_Previews: PreviewProvider {
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
        MetricLargeCellView(metric: PreviewMetric(title: "Total sales",
                                                  formattedValue: "$12,345.67",
                                                  trend: .init(direction: .up, formattedPercentage: "6%"),
                                                  chartData: sampleChart))
            .frame(width: 320, height: 70)
            .padding()
            .background(Color(.brand))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Large cell")
    }
}
#endif
