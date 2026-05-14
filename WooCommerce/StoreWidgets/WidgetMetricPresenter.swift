import Foundation

/// Pairs a `StoreInfoMetric` with the widget's configured date range so the cell can build a
/// range-aware deep-link URL. Lives in the view layer — the metric model stays range-agnostic.
struct WidgetMetricPresenter: MetricPresentable {
    let metric: StoreInfoMetric
    let dateRange: StoreStatsWidgetDateRange?

    var title: String { metric.title }
    var formattedValue: String { metric.formattedValue }
    var trend: MetricTrendPresentation? { metric.trend }
    var chartData: [MetricChartPoint]? { metric.chartData }

    var tapURL: URL? {
        guard metric.value != .unavailable, let dateRange else {
            return nil
        }
        return WidgetReportsURL.url(for: metric.type, range: dateRange)
    }
}
