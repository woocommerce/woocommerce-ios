import Foundation

#if canImport(Networking)
import Networking
#elseif canImport(NetworkingCore)
import NetworkingCore
#endif

import WooFoundationCore

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

    private let visitorStatsEndpoint: VisitorStatsEndpoint
    private let fetchTodaysRevenueAndOrders: (Int64) async throws -> OrderStatsV4
    private let fetchTodaysWPComVisitors: (Int64) async throws -> SiteSummaryStats
    private let fetchTodaysJetpackVisitors: () async throws -> SiteVisitStats

    init(credentials: Credentials, visitorStatsEndpoint: VisitorStatsEndpoint? = nil) {
        let remoteSource = RemoteSource(credentials: credentials)
        self.visitorStatsEndpoint = visitorStatsEndpoint ?? VisitorStatsEndpoint.resolve(credentials: credentials)
        fetchTodaysRevenueAndOrders = remoteSource.fetchTodaysRevenueAndOrders
        fetchTodaysWPComVisitors = remoteSource.fetchTodaysWPComVisitors
        fetchTodaysJetpackVisitors = remoteSource.fetchTodaysJetpackVisitors
    }

    init(visitorStatsEndpoint: VisitorStatsEndpoint,
         fetchTodaysRevenueAndOrders: @escaping (Int64) async throws -> OrderStatsV4,
         fetchTodaysWPComVisitors: @escaping (Int64) async throws -> SiteSummaryStats,
         fetchTodaysJetpackVisitors: @escaping () async throws -> SiteVisitStats) {
        self.visitorStatsEndpoint = visitorStatsEndpoint
        self.fetchTodaysRevenueAndOrders = fetchTodaysRevenueAndOrders
        self.fetchTodaysWPComVisitors = fetchTodaysWPComVisitors
        self.fetchTodaysJetpackVisitors = fetchTodaysJetpackVisitors
    }

    /// Async function that fetches todays stats data.
    ///
    func fetchTodayStats(for storeID: Int64) async throws -> Stats {
        switch visitorStatsEndpoint {
        case .wpComSummary:
            return try await todayStatsWithWPComVisitors(for: storeID)
        case .jetpackStatsApp:
#if canImport(Networking)
            return try await todayStatsWithJetpackVisitors(for: storeID)
#else
            return try await todayStatsWithoutVisitors(for: storeID)
#endif
        case .unavailable:
            return try await todayStatsWithoutVisitors(for: storeID)
        }
    }

    /// Fetches today stats without visitors data. Useful when that API is not available.
    ///
    private func todayStatsWithoutVisitors(for storeID: Int64) async throws -> Stats {
        let revenueAndOrders = try await fetchTodaysRevenueAndOrders(storeID)
        return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalVisitors: nil,
                     conversion: nil)
    }

    private func todayStatsWithWPComVisitors(for storeID: Int64) async throws -> Stats {
        async let revenueAndOrdersRequest = fetchTodaysRevenueAndOrders(storeID)
        async let siteStatsRequest = fetchTodaysWPComVisitors(storeID)

        do {
            let (revenueAndOrders, siteStats) = try await (revenueAndOrdersRequest, siteStatsRequest)
            return stats(from: revenueAndOrders, totalVisitors: siteStats.visitors)
        } catch {
            return try await todayStatsWithoutVisitors(for: storeID)
        }
    }

    private func todayStatsWithJetpackVisitors(for storeID: Int64) async throws -> Stats {
        async let revenueAndOrdersRequest = fetchTodaysRevenueAndOrders(storeID)
        async let siteVisitStatsRequest = fetchTodaysJetpackVisitors()

        do {
            let (revenueAndOrders, siteVisitStats) = try await (revenueAndOrdersRequest, siteVisitStatsRequest)
            guard let totalVisitors = totalVisitors(from: siteVisitStats) else {
                return try await todayStatsWithoutVisitors(for: storeID)
            }
            return stats(from: revenueAndOrders, totalVisitors: totalVisitors)
        } catch {
            return try await todayStatsWithoutVisitors(for: storeID)
        }
    }

    private func stats(from revenueAndOrders: OrderStatsV4, totalVisitors: Int) -> Stats {
        let conversion = totalVisitors > 0 ? Double(revenueAndOrders.totals.totalOrders) / Double(totalVisitors) : 0
        return Stats(revenue: revenueAndOrders.totals.grossRevenue,
                     totalOrders: revenueAndOrders.totals.totalOrders,
                     totalVisitors: totalVisitors,
                     conversion: min(conversion, 1))
    }

    private func totalVisitors(from siteVisitStats: SiteVisitStats) -> Int? {
        siteVisitStats.items?.sorted().last?.visitors
    }
}

/// Async wrappers around the networking remotes used by the widget.
///
private extension StoreInfoDataService {

    struct RemoteSource {
        private let orderStatsRemoteV4: OrderStatsRemoteV4
        private let siteStatsRemote: SiteStatsRemote
#if canImport(Networking)
        private let jetpackConnectionRemote: JetpackConnectionRemote
#endif

        init(credentials: Credentials) {
            let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
            orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
            siteStatsRemote = SiteStatsRemote(network: network)
#if canImport(Networking)
            jetpackConnectionRemote = JetpackConnectionRemote(siteURL: credentials.siteAddress, network: network)
#endif
        }

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

        /// Async wrapper that fetches todays visitors through the WP.com summary endpoint.
        ///
        func fetchTodaysWPComVisitors(for storeID: Int64) async throws -> SiteSummaryStats {
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

        /// Async wrapper that fetches todays visitors through the site-authenticated Jetpack endpoint.
        ///
        func fetchTodaysJetpackVisitors() async throws -> SiteVisitStats {
#if canImport(Networking)
            let blogID = try await jetpackConnectionRemote.fetchJetpackBlogID()
            return try await loadJetpackSiteVisitorStats(for: blogID)
#else
            throw JetpackConnectionError.blogIDUnavailable
#endif
        }

        private func loadJetpackSiteVisitorStats(for blogID: Int64) async throws -> SiteVisitStats {
            try await withCheckedThrowingContinuation { continuation in
                // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
                Task { @MainActor in
                    siteStatsRemote.loadJetpackSiteVisitorStats(for: blogID,
                                                                unit: .day,
                                                                latestDateToInclude: Date().endOfDay(timezone: .current),
                                                                quantity: 1) { result in
                        continuation.resume(with: result)
                    }
                }
            }
        }
    }
}
