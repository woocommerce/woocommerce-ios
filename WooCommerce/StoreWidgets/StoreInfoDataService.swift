import Foundation

#if canImport(Networking)
import Networking
#elseif canImport(NetworkingCore)
import NetworkingCore
#endif

import WooFoundationCore

/// Orchestrator class that fetches store stats for the widget and the Watch app.
///
final class StoreInfoDataService {

    /// Date-range parameters required to fetch a snapshot of store stats.
    ///
    /// Defined in primitive Networking types (no widget-specific types) so this service can be
    /// shared across the StoreWidgets extension and the Woo Watch App targets. Range factories
    /// for the widget's user-facing options live below; the Watch app uses `today()` directly
    /// via `fetchTodayStats(for:)`.
    ///
    struct DateRange {
        let orderStatsGranularity: StatsGranularityV4
        let orderStatsQuantity: Int
        let earliestDateToInclude: Date
        let latestDateToInclude: Date
        /// Period passed to `loadSiteSummaryStats`. The endpoint returns visitors for the
        /// calendar-aligned period containing `latestDateToInclude` — so for `last7Days` /
        /// `last30Days` the visitor total reflects the current calendar week / month rather
        /// than a strict rolling window. Order stats use the rolling earliest/latest dates
        /// above, so the two metrics can disagree on coverage early in a calendar period.
        /// Acceptable for v1; matches Yosemite's `summaryStatsGranularity` for `thisWeek` /
        /// `thisMonth`. Refining visitor coverage to a true rolling window is a follow-up.
        ///
        let summaryStatsPeriod: StatGranularity
        let timezone: TimeZone
    }

    /// Data extracted from networking types.
    ///
    struct Stats {
        let revenue: Decimal
        let netRevenue: Decimal
        let averageOrderValue: Decimal
        let totalOrders: Int
        let totalItemsSold: Int
        let totalVisitors: Int?
        let conversion: Double?
        /// Per-metric series derived from `OrderStatsV4.intervals`. Typed properties (not a
        /// `[StoreInfoMetricType: ...]` dictionary) keep this file target-portable — it is also
        /// compiled into `Woo Watch App`, which doesn't include the widget metric catalog.
        var revenueSeries: [IntervalPoint] = []
        var netRevenueSeries: [IntervalPoint] = []
        var averageOrderValueSeries: [IntervalPoint] = []
        var ordersSeries: [IntervalPoint] = []
        var itemsSoldSeries: [IntervalPoint] = []

        struct IntervalPoint: Equatable {
            let date: Date
            let value: Double
        }
    }

    /// Current-period stats paired with the matching previous-period stats so widgets can
    /// render period-over-period deltas (today → yesterday, last 7 days → previous 7 days,
    /// last 30 days → previous 30 days).
    ///
    /// `previous` is optional: a comparison-period failure should never tear down the whole
    /// widget render. When the previous-period fetch fails, `previous` is `nil` and the
    /// metric cells fall back to rendering without the trend badge.
    ///
    struct StatsPeriod {
        let current: Stats
        let previous: Stats?
    }

    /// Revenue & Orders remote source.
    ///
    private let orderStatsRemoteV4: OrderStatsRemoteV4

    /// Visitors remote source
    ///
    private let siteStatsRemote: SiteStatsRemote

    /// Network helper.
    ///
    private let network: AlamofireNetwork

    /// Whether the app is authenticated with site credentials
    ///
    private let isAuthenticatedWithoutWPCom: Bool

    init(credentials: Credentials) {
        network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        siteStatsRemote = SiteStatsRemote(network: network)
        if case .wpcom = credentials {
            isAuthenticatedWithoutWPCom = false
        } else {
            isAuthenticatedWithoutWPCom = true
        }
    }

    /// Async function that fetches today's stats. Preserved for the Woo Watch App, which
    /// renders a fixed today preset and does not need previous-period comparison — calling
    /// it bypasses the parallel previous-period fetch in `fetchStats(for:dateRange:)`.
    ///
    func fetchTodayStats(for storeID: Int64) async throws -> Stats {
        try await fetchSinglePeriodStats(for: storeID, dateRange: .today())
    }

    /// Async function that fetches stats for the given date range together with stats for
    /// the matching previous period. The two fetches run concurrently via `async let` so
    /// the second fetch does not extend overall latency.
    ///
    /// A previous-period failure is swallowed: the widget keeps rendering current-period
    /// data without trend badges instead of surfacing an error tile. A current-period
    /// failure still throws — there's no useful render without it.
    ///
    func fetchStats(for storeID: Int64, dateRange: DateRange) async throws -> StatsPeriod {
        async let currentRequest = fetchSinglePeriodStats(for: storeID, dateRange: dateRange)
        async let previousRequest = fetchSinglePeriodStats(for: storeID, dateRange: dateRange.previousPeriod())
        let current = try await currentRequest
        let previous = try? await previousRequest
        return StatsPeriod(current: current, previous: previous)
    }

    /// Internal helper that fetches stats for a single date range. The public `fetchStats`
    /// invokes this twice in parallel (current and previous period).
    ///
    private func fetchSinglePeriodStats(for storeID: Int64, dateRange: DateRange) async throws -> Stats {
        /// If user is authenticated with site credentials only,
        /// fetch revenue and orders and skip visitor stats as its endpoint is not available.
        guard !isAuthenticatedWithoutWPCom else {
            return try await statsWithoutVisitors(for: storeID, dateRange: dateRange)
        }

        // Prepare them to run in parallel
        async let revenueAndOrdersRequest = fetchRevenueAndOrders(for: storeID, dateRange: dateRange)
        async let siteStatsRequest = fetchVisitors(for: storeID, dateRange: dateRange)

        // Wait for for response
        do {
            let (revenueAndOrders, siteStats) = try await (revenueAndOrdersRequest, siteStatsRequest)

            // Assemble stats data
            let conversion = siteStats.visitors > 0 ? Double(revenueAndOrders.totals.totalOrders) / Double(siteStats.visitors) : 0
            let series = Stats.intervalSeries(from: revenueAndOrders, timezone: dateRange.timezone)
            return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                         netRevenue: revenueAndOrders.totals.netRevenue,
                         averageOrderValue: revenueAndOrders.totals.averageOrderValue,
                         totalOrders: revenueAndOrders.totals.totalOrders,
                         totalItemsSold: revenueAndOrders.totals.totalItemsSold,
                         totalVisitors: siteStats.visitors,
                         conversion: min(conversion, 1),
                         revenueSeries: series.revenue,
                         netRevenueSeries: series.netRevenue,
                         averageOrderValueSeries: series.averageOrderValue,
                         ordersSeries: series.orders,
                         itemsSoldSeries: series.itemsSold)

        } catch {

            // If there was an error fetching the stats chances are that is because jetpack is not properly configure to return stats.
            // Hence, I'm choosing to request stats without visitors again.
            // This should continue to be performant because the response should be cached.
            return try await statsWithoutVisitors(for: storeID, dateRange: dateRange)
        }
    }

    /// Fetches stats without visitors data. Useful when that API is not available.
    ///
    private func statsWithoutVisitors(for storeID: Int64, dateRange: DateRange) async throws -> Stats {
        let revenueAndOrders = try await fetchRevenueAndOrders(for: storeID, dateRange: dateRange)
        let series = Stats.intervalSeries(from: revenueAndOrders, timezone: dateRange.timezone)
        return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                     netRevenue: revenueAndOrders.totals.netRevenue,
                     averageOrderValue: revenueAndOrders.totals.averageOrderValue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalItemsSold: revenueAndOrders.totals.totalItemsSold,
                     totalVisitors: nil,
                     conversion: nil,
                     revenueSeries: series.revenue,
                     netRevenueSeries: series.netRevenue,
                     averageOrderValueSeries: series.averageOrderValue,
                     ordersSeries: series.orders,
                     itemsSoldSeries: series.itemsSold)
    }
}

// MARK: - Interval-series extraction

private extension StoreInfoDataService.Stats {
    /// Matches `DateFormatter.Stats.dateTimeFormatter` from `NetworkingCore` — inlined here
    /// because the widget extension can't import Yosemite (where the parsing helper lives).
    static let intervalDateFormat = "yyyy-MM-dd HH:mm:ss"

    /// Decomposes intervals into per-metric series. Visitors / conversion are intentionally
    /// absent — they don't come from this endpoint.
    static func intervalSeries(
        from stats: OrderStatsV4,
        timezone: TimeZone
    ) -> (revenue: [IntervalPoint],
          netRevenue: [IntervalPoint],
          averageOrderValue: [IntervalPoint],
          orders: [IntervalPoint],
          itemsSold: [IntervalPoint]) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = timezone
        formatter.dateFormat = intervalDateFormat

        // `MetricChartView` plots points by array index, so the response must be in chronological
        // order. The remote currently returns intervals in order, but sort defensively so a future
        // ordering change in the response does not produce reversed or scrambled sparklines.
        let parsed: [(date: Date, subtotals: OrderStatsV4Totals)] = stats.intervals
            .compactMap { interval in
                guard let date = formatter.date(from: interval.dateStart) else { return nil }
                return (date, interval.subtotals)
            }
            .sorted { $0.date < $1.date }
        guard !parsed.isEmpty else {
            return (revenue: [], netRevenue: [], averageOrderValue: [], orders: [], itemsSold: [])
        }

        return (
            revenue: parsed.map { IntervalPoint(date: $0.date, value: NSDecimalNumber(decimal: $0.subtotals.grossRevenue).doubleValue) },
            netRevenue: parsed.map { IntervalPoint(date: $0.date, value: NSDecimalNumber(decimal: $0.subtotals.netRevenue).doubleValue) },
            averageOrderValue: parsed.map { IntervalPoint(date: $0.date, value: NSDecimalNumber(decimal: $0.subtotals.averageOrderValue).doubleValue) },
            orders: parsed.map { IntervalPoint(date: $0.date, value: Double($0.subtotals.totalOrders)) },
            itemsSold: parsed.map { IntervalPoint(date: $0.date, value: Double($0.subtotals.totalItemsSold)) }
        )
    }
}

// MARK: - Placeholder sample

extension StoreInfoDataService.Stats {
    /// Sample values used by the widget's redacted/placeholder entry. Picked to render
    /// non-zero, plausible numbers across all catalog metrics so the placeholder reads as
    /// real data rather than a blank slate.
    ///
    static let placeholderSample = Self(
        revenue: 132.234,
        netRevenue: 120.000,
        averageOrderValue: 5.75,
        totalOrders: 23,
        totalItemsSold: 41,
        totalVisitors: 67,
        conversion: 23.0 / 67.0
    )
}

// MARK: - DateRange factories

extension StoreInfoDataService.DateRange {
    /// Today's range, used by the Watch app and by the widget's `.today` configuration.
    ///
    static func today(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        Self(orderStatsGranularity: .hourly,
             orderStatsQuantity: 24,
             earliestDateToInclude: referenceDate.startOfDay(timezone: timezone),
             latestDateToInclude: referenceDate.endOfDay(timezone: timezone),
             summaryStatsPeriod: .day,
             timezone: timezone)
    }

    /// Rolling 7-day range ending at the end of `referenceDate` (inclusive).
    ///
    /// Order stats use a true 7-day window. Visitors use `period: .week`, which the
    /// `SiteStatsRemote` endpoint resolves to the calendar week containing `referenceDate`
    /// — see the `summaryStatsPeriod` doc comment on `DateRange` for the trade-off.
    ///
    static func last7Days(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        Self(orderStatsGranularity: .daily,
             orderStatsQuantity: 7,
             earliestDateToInclude: rollingStart(daysBack: 6, referenceDate: referenceDate, timezone: timezone),
             latestDateToInclude: referenceDate.endOfDay(timezone: timezone),
             summaryStatsPeriod: .week,
             timezone: timezone)
    }

    /// Rolling 30-day range ending at the end of `referenceDate` (inclusive).
    ///
    static func last30Days(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        Self(orderStatsGranularity: .daily,
             orderStatsQuantity: 30,
             earliestDateToInclude: rollingStart(daysBack: 29, referenceDate: referenceDate, timezone: timezone),
             latestDateToInclude: referenceDate.endOfDay(timezone: timezone),
             summaryStatsPeriod: .month,
             timezone: timezone)
    }

    private static func rollingStart(daysBack: Int, referenceDate: Date, timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let startOfReferenceDay = referenceDate.startOfDay(timezone: timezone)
        return calendar.date(byAdding: .day, value: -daysBack, to: startOfReferenceDay) ?? startOfReferenceDay
    }
}

// MARK: - Previous-period comparison

extension StoreInfoDataService.DateRange {
    /// Returns the period of the same length immediately preceding this one. Used by
    /// `fetchStats(for:dateRange:)` to run a parallel comparison fetch so widgets can
    /// render period-over-period deltas (today → yesterday, last 7 days → previous 7 days,
    /// last 30 days → previous 30 days).
    ///
    /// `latestDateToInclude` is one second before this period's `earliestDateToInclude`,
    /// so the windows are contiguous. `summaryStatsPeriod` carries over so visitor stats
    /// for the previous period continue to query the same calendar granularity (.day /
    /// .week / .month) — the endpoint resolves it against the previous-period
    /// `latestDateToInclude`.
    ///
    func previousPeriod() -> Self {
        var calendar = Calendar.current
        calendar.timeZone = timezone

        // Derive the period length from the bounds rather than from `orderStatsGranularity`,
        // so this stays correct for any future range that uses hourly granularity over
        // multiple days. Both bounds are normalized to start-of-day first so DST transitions
        // don't round the day count off by one.
        let startOfEarliestDate = calendar.startOfDay(for: earliestDateToInclude)
        let startOfLatestDate = calendar.startOfDay(for: latestDateToInclude)
        let fullDays = calendar.dateComponents([.day], from: startOfEarliestDate, to: startOfLatestDate).day ?? 0
        let durationInDays = fullDays + 1

        let previousLatestDate = calendar.date(byAdding: .second, value: -1, to: earliestDateToInclude) ?? earliestDateToInclude
        let previousEarliestDate = calendar.date(byAdding: .day, value: -durationInDays, to: earliestDateToInclude) ?? earliestDateToInclude

        return Self(orderStatsGranularity: orderStatsGranularity,
                    orderStatsQuantity: orderStatsQuantity,
                    earliestDateToInclude: previousEarliestDate,
                    latestDateToInclude: previousLatestDate,
                    summaryStatsPeriod: summaryStatsPeriod,
                    timezone: timezone)
    }
}

/// Async Wrappers
///
private extension StoreInfoDataService {

    /// Async wrapper that fetches revenue and order stats for the given range.
    ///
    func fetchRevenueAndOrders(for storeID: Int64, dateRange: DateRange) async throws -> OrderStatsV4 {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                orderStatsRemoteV4.loadOrderStats(for: storeID,
                                                  unit: dateRange.orderStatsGranularity,
                                                  timeZone: dateRange.timezone,
                                                  earliestDateToInclude: dateRange.earliestDateToInclude,
                                                  latestDateToInclude: dateRange.latestDateToInclude,
                                                  quantity: dateRange.orderStatsQuantity,
                                                  forceRefresh: true) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    /// Async wrapper that fetches visitor summary stats for the given range.
    ///
    func fetchVisitors(for storeID: Int64, dateRange: DateRange) async throws -> SiteSummaryStats {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                siteStatsRemote.loadSiteSummaryStats(for: storeID,
                                                     period: dateRange.summaryStatsPeriod,
                                                     includingDate: dateRange.latestDateToInclude) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
