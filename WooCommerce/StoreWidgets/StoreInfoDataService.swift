import Foundation

#if canImport(Networking)
import Networking
import NetworkingCore
#elseif canImport(NetworkingCore)
import NetworkingCore
#endif

import WooFoundationCore

/// Orchestrator class that fetches today store stats data.
///
final class StoreInfoDataService {

    enum VisitorStatsSource {
        case wpcomSummary
        case jetpackSiteVisits
        case unavailable
    }

    /// Data extracted from networking types.
    ///
    struct Stats {
        let revenue: Decimal
        let totalOrders: Int
        let totalVisitors: Int?
        let conversion: Double?
    }

    private let visitorStatsSource: VisitorStatsSource
    private let fetchTodaysRevenueAndOrders: (Int64) async throws -> OrderStatsV4
    private let fetchTodaysWPComVisitors: (Int64) async throws -> SiteSummaryStats
    private let fetchTodaysJetpackVisitors: (Int64) async throws -> SiteVisitStats

    init(credentials: Credentials, supportsJetpackVisitorStats: Bool = false) {
        let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil) // opt out from network switching
        let orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        let siteStatsRemote = SiteStatsRemote(network: network)

        visitorStatsSource = Self.makeVisitorStatsSource(credentials: credentials,
                                                         supportsJetpackVisitorStats: supportsJetpackVisitorStats)
        fetchTodaysRevenueAndOrders = { storeID in
            try await Self.fetchTodaysRevenueAndOrders(for: storeID, with: orderStatsRemoteV4)
        }
        fetchTodaysWPComVisitors = { storeID in
            try await Self.fetchTodaysWPComVisitors(for: storeID, with: siteStatsRemote)
        }
#if canImport(Networking)
        let jetpackConnectionRemote = JetpackConnectionRemote(siteURL: credentials.siteAddress, network: network)
        fetchTodaysJetpackVisitors = { storeID in
            let blogID = try await Self.fetchJetpackBlogID(with: jetpackConnectionRemote)
            return try await Self.fetchTodaysJetpackVisitors(for: blogID, with: siteStatsRemote)
        }
#else
        fetchTodaysJetpackVisitors = { storeID in
            try await Self.fetchTodaysJetpackVisitors(for: storeID, with: siteStatsRemote)
        }
#endif
    }

    init(visitorStatsSource: VisitorStatsSource,
         fetchTodaysRevenueAndOrders: @escaping (Int64) async throws -> OrderStatsV4,
         fetchTodaysWPComVisitors: @escaping (Int64) async throws -> SiteSummaryStats,
         fetchTodaysJetpackVisitors: @escaping (Int64) async throws -> SiteVisitStats) {
        self.visitorStatsSource = visitorStatsSource
        self.fetchTodaysRevenueAndOrders = fetchTodaysRevenueAndOrders
        self.fetchTodaysWPComVisitors = fetchTodaysWPComVisitors
        self.fetchTodaysJetpackVisitors = fetchTodaysJetpackVisitors
    }

    /// Async function that fetches todays stats data.
    ///
    func fetchTodayStats(for storeID: Int64) async throws -> Stats {
        guard visitorStatsSource != .unavailable else {
            return try await todayStatsWithoutVisitors(for: storeID)
        }

        switch visitorStatsSource {
        case .wpcomSummary:
            return try await todayStatsWithWPComVisitors(for: storeID)
        case .jetpackSiteVisits:
            return try await todayStatsWithJetpackVisitors(for: storeID)
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
        async let siteVisitStatsRequest = fetchTodaysJetpackVisitors(storeID)

        do {
            let (revenueAndOrders, siteVisitStats) = try await (revenueAndOrdersRequest, siteVisitStatsRequest)
            guard let totalVisitors = Self.totalVisitors(from: siteVisitStats) else {
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
}

/// Async Wrappers
///
private extension StoreInfoDataService {

    enum JetpackVisitorStatsError: Error {
        case blogIDUnavailable
    }

    static func makeVisitorStatsSource(credentials: Credentials, supportsJetpackVisitorStats: Bool) -> VisitorStatsSource {
        switch credentials {
        case .wpcom:
            return .wpcomSummary
        case .wporg, .applicationPassword:
            return supportsJetpackVisitorStats ? .jetpackSiteVisits : .unavailable
        }
    }

    /// Async wrapper that fetches todays revenues & orders.
    ///
    static func fetchTodaysRevenueAndOrders(for storeID: Int64, with orderStatsRemoteV4: OrderStatsRemoteV4) async throws -> OrderStatsV4 {
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
    static func fetchTodaysWPComVisitors(for storeID: Int64, with siteStatsRemote: SiteStatsRemote) async throws -> SiteSummaryStats {
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
    static func fetchTodaysJetpackVisitors(for storeID: Int64, with siteStatsRemote: SiteStatsRemote) async throws -> SiteVisitStats {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                siteStatsRemote.loadJetpackSiteVisitorStats(for: storeID,
                                                            unit: .day,
                                                            latestDateToInclude: Date().endOfDay(timezone: .current),
                                                            quantity: 1) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

#if canImport(Networking)
    static func fetchJetpackBlogID(with jetpackConnectionRemote: JetpackConnectionRemote) async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                jetpackConnectionRemote.fetchJetpackConnectionData(siteID: NetworkingCore.WooConstants.placeholderSiteID) { result in
                    let mappedResult = result.flatMap { connectionData -> Result<Int64, Error> in
                        guard let blogID = connectionData.blogID else {
                            return .failure(JetpackVisitorStatsError.blogIDUnavailable)
                        }
                        return .success(blogID)
                    }
                    continuation.resume(with: mappedResult)
                }
            }
        }
    }
#endif

    static func totalVisitors(from siteVisitStats: SiteVisitStats) -> Int? {
        siteVisitStats.items?.sorted().last?.visitors
    }
}
