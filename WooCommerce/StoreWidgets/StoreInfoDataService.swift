import Networking

/// Orchestrator class that fetches today store stats data.
///
final class StoreInfoDataService {

    /// Data extracted from networking types.
    ///
    struct Stats {
        let revenue: Decimal
        let totalOrders: Int
        let totalVisitors: Int
        let conversion: Double
    }

    /// Revenue & Orders remote source.
    ///
    private var orderStatsRemoteV4: OrderStatsRemoteV4

    /// Visitors remote source
    ///
    private var siteVisitStatsRemote: SiteVisitStatsRemote

    /// Network helper.
    ///
    private var network: AlamofireNetwork

    init(authToken: String) {
        network = AlamofireNetwork(credentials: Credentials(authToken: authToken))
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        siteVisitStatsRemote = SiteVisitStatsRemote(network: network)
    }

    /// Async function that fetches stats data for given time range.
    ///
    func fetchStats(for storeID: Int64, timeRange: StatsTimeRange) async throws -> Stats {
        // Prepare them to run in parallel
        async let revenueAndOrdersRequest = fetchTodaysRevenueAndOrders(for: storeID)
        async let visitorsRequest = fetchTodaysVisitors(for: storeID)

        // Wait for for response
        let (revenueAndOrders, visitors) = try await (revenueAndOrdersRequest, visitorsRequest)

        // Assemble stats data
        let conversion = visitors.totalVisitors > 0 ? Double(revenueAndOrders.totals.totalOrders) / Double(visitors.totalVisitors) : 0
        return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalVisitors: visitors.totalVisitors,
                     conversion: min(conversion, 1))
    }
}

/// Async Wrappers
///
private extension StoreInfoDataService {

    /// Async wrapper that fetches todays revenues & orders.
    ///
    func fetchTodaysRevenueAndOrders(for storeID: Int64) async throws -> OrderStatsV4 {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                orderStatsRemoteV4.loadOrderStats(for: storeID,
                                                  unit: .hourly,
                                                  earliestDateToInclude: Date().startOfDay(timezone: .current),
                                                  latestDateToInclude: Date().endOfDay(timezone: .current),
                                                  quantity: 24,
                                                  forceRefresh: true) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    /// Async wrapper that fetches todays visitors.
    ///
    func fetchTodaysVisitors(for storeID: Int64) async throws -> SiteVisitStats {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are foreced to dispatch the call in the main thread.
            Task { @MainActor in
                siteVisitStatsRemote.loadSiteVisitorStats(for: storeID,
                                                          unit: .day,
                                                          latestDateToInclude: Date().endOfDay(timezone: .current),
                                                          quantity: 1) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
