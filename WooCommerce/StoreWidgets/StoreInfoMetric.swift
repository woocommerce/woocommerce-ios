import Foundation
import WooFoundationCore

/// Resolved raw value for a single metric at a given time range.
///
/// The case carries everything the presentation layer needs to format the value —
/// currency-typed metrics therefore include the `CurrencySettings` that produced them.
/// `.unavailable` means the data source couldn't produce a value
/// (e.g. `visitors` for a non-WPCOM site, or a metric whose fetcher isn't wired yet).
///
enum StoreInfoMetricValue: Equatable {
    case currency(Decimal, CurrencySettings?)
    case count(Int)
    /// Ratio in the 0.0 – 1.0 range.
    case percentage(Double)
    case unavailable
}

/// A metric entry — the catalog type paired with its resolved value.
///
struct StoreInfoMetric: Equatable {
    let type: StoreInfoMetricType
    let value: StoreInfoMetricValue
}
