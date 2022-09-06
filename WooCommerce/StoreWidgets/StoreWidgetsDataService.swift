import Networking

final class StoreWidgetsDataService {
    struct StoreInfoStats {
        let date: Date
        let revenue: Decimal
        let totalOrders: Int
        let totalVisitors: Int
    }

    enum NetworkingError: Error {
        case unknown
        case noInputData
    }

    private var orderStatsRemoteV4: OrderStatsRemoteV4
    private var siteVisitStatsRemote: SiteVisitStatsRemote
    private var network: AlamofireNetwork

    init(authToken: String) {
        network = AlamofireNetwork(credentials: Credentials(authToken: authToken))
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        siteVisitStatsRemote = SiteVisitStatsRemote(network: network)
    }

    func fetchDailyStatsData(for storeID: Int64, completion: @escaping (Result<StoreInfoStats, Error>) -> Void) {
        let group = DispatchGroup()
        var ordersStats: OrderStatsV4?
        var visitsStats: SiteVisitStats?
        var remoteError: Error?

        group.enter()
        orderStatsRemoteV4.loadOrderStats(for: storeID,
                                          unit: .daily,
                                          earliestDateToInclude: Calendar.current.startOfDay(for: Date()),
                                          latestDateToInclude: Date(),
                                          quantity: 1,
                                          forceRefresh: true) { result in
            switch result {
            case .success(let stats):
                ordersStats = stats
            case .failure(let error):
                remoteError = error
            }
            group.leave()
        }

        group.enter()
        siteVisitStatsRemote.loadSiteVisitorStats(for: storeID,
                                                  unit: .day,
                                                  latestDateToInclude: Date(),
                                                  quantity: 1) { result in
            switch result {
            case .success(let stats):
                visitsStats = stats
            case .failure(let error):
                remoteError = error
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if let ordersStats = ordersStats, let visitsStats = visitsStats {
                completion(.success(StoreInfoStats(date: Date(),
                                                   revenue: ordersStats.totals.netRevenue,
                                                   totalOrders: ordersStats.totals.totalOrders,
                                                   totalVisitors: visitsStats.totalVisitors)))
            } else {
                completion(.failure(remoteError ?? NetworkingError.unknown))
            }
        }
    }
}
