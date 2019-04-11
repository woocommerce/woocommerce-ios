import Foundation
import Storage


// MARK: - Storage.OrderStats: ReadOnlyConvertible
//
extension Storage.OrderStats: ReadOnlyConvertible {

    /// Updates the Storage.OrderStats with the ReadOnly.
    ///
    public func update(with stats: Yosemite.OrderStats) {
        queryID = stats.queryID
        date = stats.date
        granularity = stats.granularity.rawValue
        quantity = stats.quantity
        totalGrossSales = stats.totalGrossSales
        totalNetSales = stats.totalNetSales
        totalOrders = Int64(stats.totalOrders)
        totalProducts = Int64(stats.totalProducts)
        averageGrossSales = stats.averageGrossSales
        averageNetSales = stats.averageNetSales
        averageOrders = stats.averageOrders
        averageProducts = stats.averageProducts
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStats {
        let statItems = items?.map { $0.toReadOnly() } ?? [Yosemite.OrderStatsItem]()


        return OrderStats(queryID: queryID,
                          date: date,
                          granularity: StatGranularity(rawValue: granularity) ?? .day,
                          quantity: quantity ?? "",
                          items: statItems,
                          totalGrossSales: totalGrossSales,
                          totalNetSales: totalNetSales,
                          totalOrders: Int(totalOrders),
                          totalProducts: Int(totalProducts),
                          averageGrossSales: averageGrossSales,
                          averageNetSales: averageNetSales,
                          averageOrders: averageOrders,
                          averageProducts: averageProducts)
    }
}
