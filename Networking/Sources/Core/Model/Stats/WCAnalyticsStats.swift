import Foundation

/// Protocol for stats over a specific period, returned from a `wc-analytics` endpoint.
///
public protocol WCAnalyticsStats {
    associatedtype Totals: WCAnalyticsStatsTotals
    associatedtype Interval: WCAnalyticsStatsInterval

    /// ID for the site.
    var siteID: Int64 { get }

    /// Granularity of the stats.
    var granularity: StatsGranularityV4 { get }

    /// Totals over the entire period.
    var totals: Totals { get }

    /// Each interval within the entire period.
    var intervals: [Interval] { get }
}

/// Protocol for stats totals (the data associated with stats over a specific period) returned from a `wc-analytics` endpoint.
///
public protocol WCAnalyticsStatsTotals {
    // The stats totals will vary depending on the specific stats type.
    // These may be counts, currency amounts, etc.
}

/// Protocol for stats intervals (represents a single order stat within a larger period) returned from a `wc-analytics` endpoint.
///
public protocol WCAnalyticsStatsInterval {
    associatedtype Totals: WCAnalyticsStatsTotals

    /// Identifies which interval is represented.
    var interval: String { get }

    /// Interval start date string in the site time zone.
    var dateStart: String { get }

    /// Interval end date string in the site time zone.
    var dateEnd: String { get }

    /// Totals over the interval period.
    var subtotals: Totals { get }
}
