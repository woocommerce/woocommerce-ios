#if canImport(Networking)
import Networking
#elseif canImport(NetworkingWatchOS)
import NetworkingWatchOS
#endif

#if canImport(WooFoundationWatchOS)
import WooFoundationWatchOS
#endif

/// Orchestrator class that fetches today store stats data.
///
final class StoreInfoDataService {

    /// Data extracted from networking types.
    ///
    struct Stats {
        let revenue: Decimal
        let totalOrders: Int
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
        network = AlamofireNetwork(credentials: credentials)
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        siteStatsRemote = SiteStatsRemote(network: network)
        if case .wpcom = credentials {
            isAuthenticatedWithoutWPCom = false
        } else {
            isAuthenticatedWithoutWPCom = true
        }
    }

    /// Async function that fetches todays stats data.
    ///
    func fetchTodayStats(for storeID: Int64) async throws -> Stats {
        /// If user is authenticated with site credentials only,
        /// fetch revenue and orders and skip visitor stats as its endpoint is not available.
        guard !isAuthenticatedWithoutWPCom else {
            return try await todayStatsWithoutVisitors(for: storeID)
        }

        // Prepare them to run in parallel
        async let revenueAndOrdersRequest = fetchTodaysRevenueAndOrders(for: storeID)
        async let siteStatsRequest = fetchTodaysVisitors(for: storeID)

        // Wait for for response
        do {
            let (revenueAndOrders, siteStats) = try await (revenueAndOrdersRequest, siteStatsRequest)

            // Assemble stats data
            let conversion = siteStats.visitors > 0 ? Double(revenueAndOrders.totals.totalOrders) / Double(siteStats.visitors) : 0
            return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                         totalOrders: revenueAndOrders.totals.totalOrders,
                         totalVisitors: siteStats.visitors,
                         conversion: min(conversion, 1))

        } catch {

            // If there was an error fetching the stats chances are that is because jetpack is not properly configure to return stats.
            // Hence, I'm choosing to request stats without visitors again.
            // This should continue to be performant because the response should be cached.
            return try await todayStatsWithoutVisitors(for: storeID)
        }
    }

    /// Fetches today stats without visitors data. Useful when that API is not available.
    ///
    private func todayStatsWithoutVisitors(for storeID: Int64) async throws -> Stats {
        let revenueAndOrders = try await fetchTodaysRevenueAndOrders(for: storeID)
        return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalVisitors: nil,
                     conversion: nil)
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
                                                  timeZone: .current,
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
    func fetchTodaysVisitors(for storeID: Int64) async throws -> SiteSummaryStats {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                siteStatsRemote.loadSiteSummaryStats(for: storeID,
                                                     period: .day,
                                                     includingDate: Date().endOfDay(timezone: .current)) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
