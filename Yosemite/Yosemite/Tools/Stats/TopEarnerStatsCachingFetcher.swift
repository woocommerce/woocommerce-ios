import Foundation
import Networking

private struct ProductsReportRequestResponse: Codable {
    let items: [ProductsReportItem]
}

class TopEarnerStatsCachingFetcher {
    private let productsReportsRemote: ProductsReportsRemote
    private let cache: CodablePersistentCache<ProductsReportRequestResponse>

    init(network: Network) {
        self.productsReportsRemote = ProductsReportsRemote(network: network)
        self.cache = CodablePersistentCache<ProductsReportRequestResponse>()
    }

    @MainActor
    func loadTopEarnerStats(siteID: Int64,
                            timeRange: StatsTimeRangeV4,
                            timeZone: TimeZone,
                            earliestDateToInclude: Date,
                            latestDateToInclude: Date,
                            quantity: Int) async throws -> TopEarnerStats {
        let cacheKey = requestCacheKey(siteID: siteID,
                                       timeZone: timeZone,
                                       earliestDateToInclude: earliestDateToInclude,
                                       latestDateToInclude: latestDateToInclude,
                                       quantity: quantity)
        let response: [ProductsReportItem]
        if let cachedResponse: ProductsReportRequestResponse = try? cache.load(forKey: cacheKey) {
            response = cachedResponse.items
        } else {
            response = try await productsReportsRemote.loadTopProductsReport(for: siteID,
                                                                                       timeZone: timeZone,
                                                                                       earliestDateToInclude: earliestDateToInclude,
                                                                                       latestDateToInclude: latestDateToInclude,
                                                                                       quantity: quantity)
            let cacheEntry = CodableCacheEntry(value: ProductsReportRequestResponse(items: response), timeToLive: Constants.cacheTimeToLive)
            cache.save(cacheEntry, forKey: cacheKey)
        }

        return convertProductsReportIntoTopEarners(siteID: siteID,
                                                   granularity: timeRange.topEarnerStatsGranularity,
                                                   date: latestDateToInclude,
                                                   productsReport: response,
                                                   quantity: quantity)
    }
}

private extension TopEarnerStatsCachingFetcher {
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

    func requestCacheKey(siteID: Int64,
                         timeZone: TimeZone,
                         earliestDateToInclude: Date,
                         latestDateToInclude: Date,
                         quantity: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd:MM:yy"

        let stringArray = [String(siteID),
                           timeZone.identifier,
                           dateFormatter.string(from: earliestDateToInclude),
                           dateFormatter.string(from: latestDateToInclude),
                           String(quantity)]

        return stringArray.joined(separator: "-")
    }
}

private enum Constants {
    static let cacheTimeToLive: TimeInterval = 60*30
}
