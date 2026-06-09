import Foundation
import WidgetKit

/// Type that represents the all the possible Widget states.
///
enum StoreInfoEntry: TimelineEntry {
    // Represents a not logged-in state
    case notConnected

    // Represents a fetching error state
    case error

    // Represents a fetched data state
    case data(StoreInfoData)

    // Current date, needed by the `TimelineEntry` protocol.
    var date: Date { Date() }
}

/// Type that represents the the widget state data.
///
/// Lock-screen widgets read the pre-formatted String fields directly. The home-screen widget
/// uses the metric catalog via `metricSlots`. The provider populates both shapes.
///
struct StoreInfoData {
    /// Eg: Today, Weekly, Monthly, Yearly
    ///
    var range: String

    /// Store name
    ///
    var name: String

    /// Revenue at the range (eg: today)
    ///
    var revenue: String

    /// Revenue at the range (eg: today) in compact format (eg: $12k)
    ///
    var revenueCompact: String

    /// Visitors count at the range (eg: today)
    ///
    var visitors: String

    /// Order count at the range (eg: today)
    ///
    var orders: String

    /// Conversion at the range (eg: today)
    ///
    var conversion: String

    /// Time when the widget was last refreshed (eg: 10.24PM)
    ///
    var updatedTime: String

    /// Slot-preserving metric entries for the metric-driven widget path. Explicit "None"
    /// selections become `.empty` so the UI can keep the configured position blank.
    ///
    var metricSlots: [StoreInfoMetricSlot]

    /// Concrete metric entries, derived from `metricSlots` for analytics and other readers
    /// that should ignore explicit empty slots.
    ///
    var metrics: [StoreInfoMetric] {
        metricSlots.compactMap(\.concreteMetric)
    }

    /// User-selected color scheme. Drives the background, text colors, logo tint, and
    /// chart palette via `StoreWidgetTheme`.
    ///
    var theme: StoreWidgetTheme

    init(range: String,
         name: String,
         revenue: String,
         revenueCompact: String,
         visitors: String,
         orders: String,
         conversion: String,
         updatedTime: String,
         metrics: [StoreInfoMetric] = [],
         metricSlots: [StoreInfoMetricSlot]? = nil,
         dateRange: StoreStatsWidgetDateRange? = nil,
         theme: StoreWidgetTheme = .brandPurple) {
        self.range = range
        self.name = name
        self.revenue = revenue
        self.revenueCompact = revenueCompact
        self.visitors = visitors
        self.orders = orders
        self.conversion = conversion
        self.updatedTime = updatedTime
        self.metricSlots = metricSlots ?? metrics.map { .metric($0) }
        self.dateRange = dateRange
        self.theme = theme
    }

    /// Used to build per-cell deep-link URLs. `nil` for surfaces without a configured range.
    var dateRange: StoreStatsWidgetDateRange? = nil
}

extension StoreInfoData {
    /// Returns the entry for the given metric type, or an `.unavailable` placeholder
    /// if the metric isn't present in the current data set.
    ///
    /// A miss is treated as a wiring bug (provider didn't include an expected metric);
    /// `assertionFailure` catches it in debug, while production falls through to the
    /// placeholder so the widget still renders as `-` instead of crashing.
    ///
    func metric(of type: StoreInfoMetricType) -> StoreInfoMetric {
        if let metric = metrics.first(where: { $0.type == type }) {
            return metric
        }
        assertionFailure("StoreInfoData missing expected metric: \(type.rawValue)")
        return StoreInfoMetric(type: type, value: .unavailable)
    }

    /// Wraps each metric in a `WidgetMetricPresenter` paired with the configured date range.
    var presentableMetrics: [any MetricPresentable] {
        metrics.map { WidgetMetricPresenter(metric: $0, dateRange: dateRange) }
    }
}
