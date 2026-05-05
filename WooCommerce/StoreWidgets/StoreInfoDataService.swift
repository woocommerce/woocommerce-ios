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
    /// renders a fixed today preset.
    ///
    func fetchTodayStats(for storeID: Int64) async throws -> Stats {
        try await fetchStats(for: storeID, dateRange: .today())
    }

    /// Async function that fetches stats for the given date range.
    ///
    func fetchStats(for storeID: Int64, dateRange: DateRange) async throws -> Stats {
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
            return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                         netRevenue: revenueAndOrders.totals.netRevenue,
                         averageOrderValue: revenueAndOrders.totals.averageOrderValue,
                         totalOrders: revenueAndOrders.totals.totalOrders,
                         totalItemsSold: revenueAndOrders.totals.totalItemsSold,
                         totalVisitors: siteStats.visitors,
                         conversion: min(conversion, 1))

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
        return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                     netRevenue: revenueAndOrders.totals.netRevenue,
                     averageOrderValue: revenueAndOrders.totals.averageOrderValue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalItemsSold: revenueAndOrders.totals.totalItemsSold,
                     totalVisitors: nil,
                     conversion: nil)
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
