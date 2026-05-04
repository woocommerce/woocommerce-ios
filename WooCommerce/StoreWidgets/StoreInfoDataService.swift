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

    /// Visitor stats endpoint to use.
    ///
    private let visitorStatsEndpoint: VisitorStatsEndpoint

#if canImport(Networking)
    /// Blog ID remote source.
    ///
    private let jetpackConnectionRemote: JetpackConnectionRemote
#endif

    init(credentials: Credentials, visitorStatsEndpoint: VisitorStatsEndpoint? = nil) {
        network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        siteStatsRemote = SiteStatsRemote(network: network)
        self.visitorStatsEndpoint = visitorStatsEndpoint ?? VisitorStatsEndpoint.resolve(credentials: credentials)
#if canImport(Networking)
        jetpackConnectionRemote = JetpackConnectionRemote(siteURL: credentials.siteAddress, network: network)
#endif
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
        switch visitorStatsEndpoint {
        case .wpComSummary:
            return try await statsWithWPComVisitors(for: storeID, dateRange: dateRange)
        case .jetpackStatsApp:
#if canImport(Networking)
            return try await statsWithJetpackVisitors(for: storeID, dateRange: dateRange)
#else
            return try await statsWithoutVisitors(for: storeID, dateRange: dateRange)
#endif
        case .unavailable:
            return try await statsWithoutVisitors(for: storeID, dateRange: dateRange)
        }
    }

    private func statsWithWPComVisitors(for storeID: Int64, dateRange: DateRange) async throws -> Stats {
        async let revenueAndOrdersRequest = fetchRevenueAndOrders(for: storeID, dateRange: dateRange)
        async let visitorsRequest = fetchWPComVisitors(for: storeID, dateRange: dateRange)

        do {
            let (revenueAndOrders, siteStats) = try await (revenueAndOrdersRequest, visitorsRequest)
            return stats(from: revenueAndOrders, totalVisitors: siteStats.visitors)
        } catch {
            return try await statsWithoutVisitors(for: storeID, dateRange: dateRange)
        }
    }

    private func statsWithJetpackVisitors(for storeID: Int64, dateRange: DateRange) async throws -> Stats {
        async let revenueAndOrdersRequest = fetchRevenueAndOrders(for: storeID, dateRange: dateRange)
        async let siteVisitStatsRequest = fetchJetpackVisitors(dateRange: dateRange)

        do {
            let (revenueAndOrders, siteVisitStats) = try await (revenueAndOrdersRequest, siteVisitStatsRequest)
            guard let totalVisitors = totalVisitors(from: siteVisitStats) else {
                return try await statsWithoutVisitors(for: storeID, dateRange: dateRange)
            }
            return stats(from: revenueAndOrders, totalVisitors: totalVisitors)
        } catch {
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

    private func stats(from revenueAndOrders: OrderStatsV4, totalVisitors: Int) -> Stats {
        let conversion = totalVisitors > 0 ? Double(revenueAndOrders.totals.totalOrders) / Double(totalVisitors) : 0
        return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                     netRevenue: revenueAndOrders.totals.netRevenue,
                     averageOrderValue: revenueAndOrders.totals.averageOrderValue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalItemsSold: revenueAndOrders.totals.totalItemsSold,
                     totalVisitors: totalVisitors,
                     conversion: min(conversion, 1))
    }

    private func totalVisitors(from siteVisitStats: SiteVisitStats) -> Int? {
        guard let items = siteVisitStats.items, items.isEmpty == false else {
            return nil
        }
        return items.map { $0.visitors }.reduce(0, +)
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

    /// Async wrapper that fetches visitor summary stats through the WP.com endpoint for the given range.
    ///
    func fetchWPComVisitors(for storeID: Int64, dateRange: DateRange) async throws -> SiteSummaryStats {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                siteStatsRemote.loadSiteSummaryStats(for: storeID,
                                                     siteTimezone: dateRange.timezone,
                                                     period: dateRange.summaryStatsPeriod,
                                                     includingDate: dateRange.latestDateToInclude) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    /// Async wrapper that fetches visitor stats through the site-authenticated Jetpack endpoint for the given range.
    ///
    func fetchJetpackVisitors(dateRange: DateRange) async throws -> SiteVisitStats {
#if canImport(Networking)
        let blogID = try await jetpackConnectionRemote.fetchJetpackBlogID()
        return try await loadJetpackSiteVisitorStats(for: blogID, dateRange: dateRange)
#else
        throw JetpackConnectionError.blogIDUnavailable
#endif
    }

    private func loadJetpackSiteVisitorStats(for blogID: Int64, dateRange: DateRange) async throws -> SiteVisitStats {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                siteStatsRemote.loadJetpackSiteVisitorStats(for: blogID,
                                                            siteTimezone: dateRange.timezone,
                                                            unit: dateRange.summaryStatsPeriod,
                                                            latestDateToInclude: dateRange.latestDateToInclude,
                                                            quantity: 1) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
