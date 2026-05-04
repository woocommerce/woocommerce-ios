import Foundation

/// Presentation-layer protocol consumed by `MetricCellView`.
///
/// Decouples the cell view from `StoreInfoMetric`, so previews and tests can provide
/// arbitrary conforming stubs without constructing the full metric type.
///
protocol MetricPresentable {
    var title: String { get }
    var formattedValue: String { get }
    /// URL the cell should deep-link to when tapped. `nil` means non-tappable.
    var tapURL: URL? { get }
}

extension MetricPresentable {
    var tapURL: URL? { nil }
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

    var tapURL: URL? {
        switch type {
        case .orders:
            return WooConstants.URLs.ordersScreen.asURL()
        case .revenue, .netSales, .itemsSold, .visitors, .conversion, .averageOrderValue:
            return nil
        }
    }
}
