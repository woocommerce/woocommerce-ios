import Foundation

/// Presentation-layer protocol consumed by `MetricCellView`.
///
/// Decouples the cell view from `StoreInfoMetric`, so previews and tests can provide
/// arbitrary conforming stubs without constructing the full metric type.
///
protocol MetricPresentable {
    var title: String { get }
    var formattedValue: String { get }
    var trend: MetricTrendPresentation? { get }
    /// URL the cell should deep-link to when tapped. `nil` means non-tappable.
    var tapURL: URL? { get }
    /// Time-series for the trailing per-cell chart. `nil` or `< 2` points renders no chart.
    var chartData: [MetricChartPoint]? { get }
}

extension MetricPresentable {
    var trend: MetricTrendPresentation? { nil }
    var tapURL: URL? { nil }
    var chartData: [MetricChartPoint]? { nil }
}

struct MetricChartPoint: Equatable {
    let date: Date
    let value: Double
}

/// Presentation-ready trend badge data: a direction (up/down) plus a localized
/// formatted percentage delta (e.g. `"6%"`).
///
struct MetricTrendPresentation: Equatable {
    enum Direction: Equatable {
        case up
        case down
        /// No change between current and previous period. Rendered as a bare gray
        /// dash (no percentage text) so the cell still reads as "we have data" rather
        /// than blank.
        case flat
    }

    let direction: Direction
    let formattedPercentage: String
}

// MARK: - StoreInfoMetric

/// `tapURL` is intentionally unimplemented here — URLs are range-aware and the metric model
/// is range-agnostic. Container views wrap metrics in `WidgetMetricPresenter` to compute it.
extension StoreInfoMetric: MetricPresentable {
    var title: String {
        type.displayName
    }

    var formattedValue: String {
        switch value {
        case .currency(let amount, let currencySettings):
            return StoreInfoFormatter.formattedAmountCompactString(
                for: amount,
                with: currencySettings
            )
        case .count(let count):
            return NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
        case .percentage(let ratio):
            return StoreInfoFormatter.formattedConversionString(
                for: ratio
            )
        case .unavailable:
            return StoreInfoFormatter.Constants.valuePlaceholderText
        }
    }

    var trend: MetricTrendPresentation? {
        value.trend(comparedTo: previousValue)
    }

    var chartData: [MetricChartPoint]? {
        chartSeries
    }
}

// MARK: - Trend computation

private extension StoreInfoMetricValue {
    /// Returns a presentation-ready trend, or `nil` when comparison is not meaningful
    /// (missing previous value, non-numeric value, or negative baseline).
    ///
    /// Zero deltas and sub-1% deltas that round to 0% surface as `.flat` with a "0%"
    /// label so the badge still indicates that we have data — just unchanged.
    ///
    func trend(comparedTo previousValue: StoreInfoMetricValue?) -> MetricTrendPresentation? {
        guard let current = trendComparableValue,
              let previous = previousValue?.trendComparableValue,
              current.isFinite,
              previous.isFinite else {
            return nil
        }
        guard previous >= 0 else {
            return nil
        }

        let delta = current - previous
        // Previous = 0 → any non-zero current is a 100% change relative to baseline.
        let ratio = previous == 0 ? (delta == 0 ? 0 : 1) : abs(delta / previous)
        guard let formattedPercentage = formattedTrendPercentage(for: ratio),
              let zeroFormattedPercentage = formattedTrendPercentage(for: 0) else {
            return nil
        }

        let direction: MetricTrendPresentation.Direction
        if delta == 0 || formattedPercentage == zeroFormattedPercentage {
            direction = .flat
            return MetricTrendPresentation(direction: direction,
                                           formattedPercentage: zeroFormattedPercentage)
        } else {
            direction = delta > 0 ? .up : .down
            return MetricTrendPresentation(direction: direction,
                                           formattedPercentage: formattedPercentage)
        }
    }

    /// Numeric projection used by the trend comparison. `.unavailable` returns `nil`
    /// so the cell renders without a trend badge.
    var trendComparableValue: Double? {
        switch self {
        case .currency(let amount, _):
            return NSDecimalNumber(decimal: amount).doubleValue
        case .count(let count):
            return Double(count)
        case .percentage(let ratio):
            return ratio
        case .unavailable:
            return nil
        }
    }

    func formattedTrendPercentage(for ratio: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: ratio))
    }
}
