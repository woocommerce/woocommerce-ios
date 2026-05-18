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
        let summaryStatsPeriod: StatGranularity
        let timezone: TimeZone
        /// Set for ranges whose previous window doesn't fit "same length immediately
        /// preceding" — week-to-date / month-to-date use a calendar-aligned previous window.
        let previousPeriodOverride: PreviousPeriodOverride?

        struct PreviousPeriodOverride {
            let earliestDateToInclude: Date
            let latestDateToInclude: Date
        }

        init(orderStatsGranularity: StatsGranularityV4,
             orderStatsQuantity: Int,
             earliestDateToInclude: Date,
             latestDateToInclude: Date,
             summaryStatsPeriod: StatGranularity,
             timezone: TimeZone,
             previousPeriodOverride: PreviousPeriodOverride? = nil) {
            self.orderStatsGranularity = orderStatsGranularity
            self.orderStatsQuantity = orderStatsQuantity
            self.earliestDateToInclude = earliestDateToInclude
            self.latestDateToInclude = latestDateToInclude
            self.summaryStatsPeriod = summaryStatsPeriod
            self.timezone = timezone
            self.previousPeriodOverride = previousPeriodOverride
        }
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
        conversion: 23.0 / 67.0,
        revenueSeries: placeholderSeries(values: [
            0, 0, 0, 0, 0.5, 1, 2, 3.5, 6.8, 9.5, 12.8, 14,
            11.6, 10.8, 12.9, 13.2, 11.8, 8.9, 5.7, 3.6, 2, 1, 0.6, 0.034
        ]),
        netRevenueSeries: placeholderSeries(values: [
            0, 0, 0, 0, 0.4, 0.9, 1.8, 3.2, 6.1, 8.7, 11.6, 12.9,
            10.6, 9.7, 11.8, 11.7, 10.7, 8.1, 5.1, 3.2, 1.8, 0.9, 0.5, 0.3
        ]),
        averageOrderValueSeries: placeholderSeries(values: [
            0, 0, 0, 0, 3.1, 4.2, 4.8, 5.1, 5.6, 5.9, 6.2, 6.1,
            5.8, 5.6, 5.9, 6.3, 6, 5.7, 5.2, 4.9, 4.6, 4.1, 3.7, 3.2
        ]),
        ordersSeries: placeholderSeries(values: [
            0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3,
            2, 2, 2, 3, 2, 1, 1, 0, 0, 0, 0, 0
        ]),
        itemsSoldSeries: placeholderSeries(values: [
            0, 0, 0, 0, 0, 1, 1, 1, 2, 3, 4, 5,
            4, 3, 4, 5, 3, 2, 2, 1, 0, 0, 0, 0
        ])
    )

    /// Previous-period sample used by the widget gallery placeholder to render trend badges.
    static let placeholderPreviousSample = Self(
        revenue: 118.000,
        netRevenue: 125.000,
        averageOrderValue: 5.20,
        totalOrders: 31,
        totalItemsSold: 34,
        totalVisitors: 71,
        conversion: 0.29
    )

    private static func placeholderSeries(values: [Double]) -> [IntervalPoint] {
        values.enumerated().map { index, value in
            IntervalPoint(date: Date(timeIntervalSinceReferenceDate: Double(index * 3_600)), value: value)
        }
    }
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

    static func yesterday(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        let calendar = makeCalendar(timezone: timezone)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate
        return Self(orderStatsGranularity: .hourly,
                    orderStatsQuantity: 24,
                    earliestDateToInclude: yesterday.startOfDay(timezone: timezone),
                    latestDateToInclude: yesterday.endOfDay(timezone: timezone),
                    summaryStatsPeriod: .day,
                    timezone: timezone)
    }

    static func lastWeek(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        let calendar = makeCalendar(timezone: timezone)
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
        let earliest = oneWeekAgo.startOfWeek(timezone: timezone, calendar: calendar) ?? oneWeekAgo.startOfDay(timezone: timezone)
        let latest = oneWeekAgo.endOfWeek(timezone: timezone, calendar: calendar) ?? oneWeekAgo.endOfDay(timezone: timezone)
        return Self(orderStatsGranularity: .daily,
                    orderStatsQuantity: 7,
                    earliestDateToInclude: earliest,
                    latestDateToInclude: latest,
                    summaryStatsPeriod: .week,
                    timezone: timezone)
    }

    /// Override needed because calendar months have variable length; the default
    /// derivation would slide back 30 days from Apr 1 → Mar 2 instead of Mar 1.
    static func lastMonth(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        let calendar = makeCalendar(timezone: timezone)
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        let currentEarliest = oneMonthAgo.startOfMonth(timezone: timezone) ?? oneMonthAgo.startOfDay(timezone: timezone)
        let currentLatest = oneMonthAgo.endOfMonth(timezone: timezone) ?? oneMonthAgo.endOfDay(timezone: timezone)

        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: referenceDate) ?? referenceDate
        let previousEarliest = twoMonthsAgo.startOfMonth(timezone: timezone) ?? twoMonthsAgo.startOfDay(timezone: timezone)
        let previousLatest = twoMonthsAgo.endOfMonth(timezone: timezone) ?? twoMonthsAgo.endOfDay(timezone: timezone)

        return Self(orderStatsGranularity: .daily,
                    orderStatsQuantity: 31,
                    earliestDateToInclude: currentEarliest,
                    latestDateToInclude: currentLatest,
                    summaryStatsPeriod: .month,
                    timezone: timezone,
                    previousPeriodOverride: .init(
                        earliestDateToInclude: previousEarliest,
                        latestDateToInclude: previousLatest))
    }

    /// `latestDateToInclude` extends to end-of-week intentionally — mirrors the hub's
    /// future-tolerant end so the endpoint returns all available data across timezone edges.
    static func weekToDate(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        let calendar = makeCalendar(timezone: timezone)
        let currentEarliest = referenceDate.startOfWeek(timezone: timezone, calendar: calendar)
            ?? referenceDate.startOfDay(timezone: timezone)
        let currentLatest = referenceDate.endOfWeek(timezone: timezone, calendar: calendar)
            ?? referenceDate.endOfDay(timezone: timezone)

        let previousLatest = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
        let previousEarliest = previousLatest.startOfWeek(timezone: timezone, calendar: calendar)
            ?? previousLatest.startOfDay(timezone: timezone)

        return Self(orderStatsGranularity: .daily,
                    orderStatsQuantity: 7,
                    earliestDateToInclude: currentEarliest,
                    latestDateToInclude: currentLatest,
                    summaryStatsPeriod: .week,
                    timezone: timezone,
                    previousPeriodOverride: .init(
                        earliestDateToInclude: previousEarliest,
                        latestDateToInclude: previousLatest))
    }

    static func monthToDate(referenceDate: Date = Date(), timezone: TimeZone = .current) -> Self {
        let calendar = makeCalendar(timezone: timezone)
        let currentEarliest = referenceDate.startOfMonth(timezone: timezone)
            ?? referenceDate.startOfDay(timezone: timezone)
        let currentLatest = referenceDate.endOfMonth(timezone: timezone)
            ?? referenceDate.endOfDay(timezone: timezone)

        let previousLatest = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        let previousEarliest = previousLatest.startOfMonth(timezone: timezone)
            ?? previousLatest.startOfDay(timezone: timezone)

        return Self(orderStatsGranularity: .daily,
                    orderStatsQuantity: 31,
                    earliestDateToInclude: currentEarliest,
                    latestDateToInclude: currentLatest,
                    summaryStatsPeriod: .month,
                    timezone: timezone,
                    previousPeriodOverride: .init(
                        earliestDateToInclude: previousEarliest,
                        latestDateToInclude: previousLatest))
    }

    private static func makeCalendar(timezone: TimeZone) -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar
    }
}

// MARK: - Previous-period comparison

extension StoreInfoDataService.DateRange {
    /// Uses `previousPeriodOverride` when set, otherwise derives "same length immediately
    /// preceding" from the current bounds.
    func previousPeriod() -> Self {
        if let previousPeriodOverride {
            return Self(orderStatsGranularity: orderStatsGranularity,
                        orderStatsQuantity: orderStatsQuantity,
                        earliestDateToInclude: previousPeriodOverride.earliestDateToInclude,
                        latestDateToInclude: previousPeriodOverride.latestDateToInclude,
                        summaryStatsPeriod: summaryStatsPeriod,
                        timezone: timezone)
        }

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
