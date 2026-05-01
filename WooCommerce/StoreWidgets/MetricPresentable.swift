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
}

extension MetricPresentable {
    var trend: MetricTrendPresentation? { nil }
    var tapURL: URL? { nil }
}

/// Presentation-ready trend badge data: a direction (up/down) plus a localized
/// formatted percentage delta (e.g. `"6%"`).
///
struct MetricTrendPresentation: Equatable {
    enum Direction: Equatable {
        case up
        case down
    }

    let direction: Direction
    let formattedPercentage: String
}

// MARK: - StoreInfoMetric

/// Format policy (v1): currency values use the compact form (e.g. `$12k`) on all surfaces.
/// Size-specific formatting (full on `.systemLarge`, compact on `.systemSmall`) is a later
/// refinement — swap in a size-aware formatter, not a different cell.
///
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

    var tapURL: URL? {
        switch type {
        case .orders:
            return WooConstants.URLs.ordersScreen.asURL()
        case .revenue, .netSales, .itemsSold, .visitors, .conversion, .averageOrderValue:
            return nil
        }
    }
}

// MARK: - Trend computation

private extension StoreInfoMetricValue {
    /// Returns a presentation-ready trend, or `nil` when comparison is not meaningful
    /// (missing previous value, non-numeric value, or zero delta).
    ///
    func trend(comparedTo previousValue: StoreInfoMetricValue?) -> MetricTrendPresentation? {
        guard let current = trendComparableValue,
              let previous = previousValue?.trendComparableValue,
              current.isFinite,
              previous.isFinite else {
            return nil
        }

        let delta = current - previous
        guard delta != 0 else {
            return nil
        }

        let direction: MetricTrendPresentation.Direction = delta > 0 ? .up : .down
        // Previous = 0 → any non-zero current is a 100% change relative to baseline.
        let ratio = previous == 0 ? 1 : abs(delta / previous)
        return MetricTrendPresentation(direction: direction,
                                       formattedPercentage: formattedTrendPercentage(for: ratio))
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

    func formattedTrendPercentage(for ratio: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: ratio)) ?? StoreInfoFormatter.Constants.valuePlaceholderText
    }
}
