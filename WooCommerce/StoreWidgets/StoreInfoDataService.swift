import Networking

/// Orchestrator class that fetches store stats data.
///
final class StoreInfoDataService {

    /// Data extracted from networking types.
    ///
    struct Stats {
        let timeRange: StatsTimeRange
        let revenue: Decimal
        let totalOrders: Int
        let totalVisitors: Int
        let conversion: Double
    }

    enum DataError: Error {
        case rangeDatesNil
    }

    /// Revenue & Orders remote source.
    ///
    private var orderStatsRemoteV4: OrderStatsRemoteV4

    /// Visitors remote source
    ///
    private var siteVisitStatsRemote: SiteStatsRemote

    /// Network helper.
    ///
    private var network: AlamofireNetwork

    init(authToken: String) {
        network = AlamofireNetwork(credentials: Credentials(authToken: authToken))
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        siteVisitStatsRemote = SiteStatsRemote(network: network)
    }

    /// Async function that fetches stats data for given time range.
    ///
    func fetchStats(for storeID: Int64, timeRange: StatsTimeRange) async throws -> Stats {
        // Prepare them to run in parallel
        async let revenueAndOrdersRequest = fetchRevenueAndOrders(for: storeID, timeRange: timeRange)
        async let visitorsRequest = fetchVisitors(for: storeID, timeRange: timeRange)

        // Wait for for response
        let (revenueAndOrders, visitors) = try await (revenueAndOrdersRequest, visitorsRequest)

        // Assemble stats data
        let conversion = visitors.totalVisitors > 0 ? Double(revenueAndOrders.totals.totalOrders) / Double(visitors.totalVisitors) : 0
        return Stats(timeRange: timeRange,
                     revenue: revenueAndOrders.totals.grossRevenue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalVisitors: visitors.totalVisitors,
                     conversion: min(conversion, 1))
    }
}

/// Async Wrappers
///
private extension StoreInfoDataService {

    /// Async wrapper that fetches revenues & orders.
    ///
    func fetchRevenueAndOrders(for storeID: Int64, timeRange: StatsTimeRange) async throws -> OrderStatsV4 {
        guard let earliestDateToInclude = timeRange.earliestDate(latestDate: Date(), siteTimezone: .current),
              let latestDateToInclude = timeRange.latestDate(currentDate: Date(), siteTimezone: .current) else {
            throw DataError.rangeDatesNil
        }

        return try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                orderStatsRemoteV4.loadOrderStats(for: storeID,
                                                  unit: timeRange.intervalGranularity,
                                                  earliestDateToInclude: earliestDateToInclude,
                                                  latestDateToInclude: latestDateToInclude,
                                                  quantity: timeRange.maxNumberOfIntervals,
                                                  forceRefresh: true) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    /// Async wrapper that fetches visitors.
    ///
    func fetchVisitors(for storeID: Int64, timeRange: StatsTimeRange) async throws -> SiteVisitStats {
        guard let latestDateToInclude = timeRange.latestDate(currentDate: Date(), siteTimezone: .current) else {
            throw DataError.rangeDatesNil
        }

        return try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                let quantity = timeRange.siteVisitStatsQuantity(date: latestDateToInclude, siteTimezone: .current)
                siteVisitStatsRemote.loadSiteVisitorStats(for: storeID,
                                                          unit: timeRange.siteVisitStatsGranularity,
                                                          latestDateToInclude: latestDateToInclude,
                                                          quantity: quantity) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
