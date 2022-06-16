import Networking
import Foundation

final class StatsWidgetsService {
    private var orderStatsRemoteV4: OrderStatsRemoteV4
    private var siteVisitStatsRemote: SiteVisitStatsRemote
    private var network: AlamofireNetwork

    init(authToken: String) {
        network = AlamofireNetwork(credentials: Credentials(authToken: authToken))
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        siteVisitStatsRemote = SiteVisitStatsRemote(network: network)
    }

    func fetchStatsWidgetData(for storeID: Int64, earliestDateToInclude: Date) async throws -> StatsWidgetData {
        async let orderStats = loadOrderStats(for: storeID, earliestDateToInclude: earliestDateToInclude)
        async let visitStats = loadSiteVisitorStats(for: storeID)

        return StatsWidgetData(revenue: try await orderStats.totals.netRevenue,
                               orders: try await orderStats.totals.totalOrders,
                               visitors: try? await visitStats.totalVisitors)
    }

    func loadSiteVisitorStats(for storeID: Int64) async throws -> SiteVisitStats {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                siteVisitStatsRemote.loadSiteVisitorStats(for: storeID,
                                                           unit: .week,
                                                           latestDateToInclude: Date(),
                                                           quantity: 1) { result in
                    switch result {
                    case .success(_):
                        continuation.resume(with: result)

                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func loadOrderStats(for storeID: Int64, earliestDateToInclude: Date) async throws -> OrderStatsV4 {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                orderStatsRemoteV4.loadOrderStats(for: storeID,
                                                   unit: .weekly,
                                                   earliestDateToInclude: earliestDateToInclude,
                                        latestDateToInclude: Date(),
                                        quantity: 1) { result in
                    switch result {
                    case .success(_):
                        continuation.resume(with: result)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
