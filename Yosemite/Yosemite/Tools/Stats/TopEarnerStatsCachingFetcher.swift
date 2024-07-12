import Foundation
import Networking

class TopEarnerStatsCachingFetcher {
    private let productsReportsRemote: ProductsReportsRemote

    init(network: Network) {
        self.productsReportsRemote = ProductsReportsRemote(network: network)
    }

    func loadTopEarnerStats(siteID: Int64,
                            timeRange: StatsTimeRangeV4,
                            timeZone: TimeZone,
                            earliestDateToInclude: Date,
                            latestDateToInclude: Date,
                            quantity: Int) async throws -> TopEarnerStats {
        guard let cachedTopEarnersStats: TopEarnerStats = CodableStatsCache.loadValue(from: earliestDateToInclude...latestDateToInclude,
                                                                                      siteID: siteID),
              cachedTopEarnersStats.granularity == timeRange.topEarnerStatsGranularity,
              cachedTopEarnersStats.limit == quantity.description else {
            let topEarners = try await retrieveTopEarnersRemotely(for: siteID,
                                                  timeRange: timeRange,
                                                  timeZone: timeZone,
                                                  earliestDateToInclude: earliestDateToInclude,
                                                  latestDateToInclude: latestDateToInclude,
                                                  quantity: quantity)
            CodableStatsCache.save(value: topEarners, range: earliestDateToInclude...latestDateToInclude, siteID: siteID, timeToLive: Constants.cacheTimeToLive)

            return topEarners
        }

        return cachedTopEarnersStats
    }
}

private extension TopEarnerStatsCachingFetcher {
    @MainActor
    func retrieveTopEarnersRemotely(for siteID: Int64,
                                    timeRange: StatsTimeRangeV4,
                                    timeZone: TimeZone,
                                    earliestDateToInclude: Date,
                                    latestDateToInclude: Date,
                                    quantity: Int) async throws -> TopEarnerStats {
        guard let cachedTopEarnersStats: TopEarnerStats = CodableStatsCache.loadValue(from: earliestDateToInclude...latestDateToInclude,
                                                                                      siteID: siteID) else {
            let productsReport = try await productsReportsRemote.loadTopProductsReport(for: siteID,
                                                                                       timeZone: timeZone,
                                                                                       earliestDateToInclude: earliestDateToInclude,
                                                                                       latestDateToInclude: latestDateToInclude,
                                                                                       quantity: quantity)
            return convertProductsReportIntoTopEarners(siteID: siteID,
                                                       granularity: timeRange.topEarnerStatsGranularity,
                                                       date: latestDateToInclude,
                                                       productsReport: productsReport,
                                                       quantity: quantity)

        }

        return cachedTopEarnersStats
    }

    /// Converts the `[ProductsReportItem]` list in a Products analytics report into `TopEarnerStats`
    ///
    func convertProductsReportIntoTopEarners(siteID: Int64,
                                                  granularity: StatGranularity,
                                                  date: Date,
                                                  productsReport: [ProductsReportItem],
                                                  quantity: Int) -> TopEarnerStats {
        let statsDate = StatsStoreV4.buildDateString(from: date, with: granularity)
        let statsItems = productsReport.map { product in
            TopEarnerStatsItem(productID: product.productID,
                               productName: product.productName,
                               quantity: product.quantity,
                               total: product.total,
                               currency: "", // TODO: Remove currency https://github.com/woocommerce/woocommerce-ios/issues/2549
                               imageUrl: product.imageUrl)
        }
        return TopEarnerStats(siteID: siteID, date: statsDate, granularity: granularity, limit: quantity.description, items: statsItems)
    }
}

private enum Constants {
    static let cacheTimeToLive: TimeInterval = 60*30
}
