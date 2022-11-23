import Foundation
import Yosemite

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    /// Revenue Card ViewModel
    ///
    @Published var revenueCard = AnalyticsReportCardViewModel(title: "REVENUE",
                                                              leadingTitle: "Total Sales",
                                                              leadingValue: "$3.234",
                                                              leadingDelta: "+23%",
                                                              leadingDeltaColor: .withColorStudio(.green, shade: .shade50),
                                                              trailingTitle: "Net Sales",
                                                              trailingValue: "$2.324",
                                                              trailingDelta: "-4%",
                                                              trailingDeltaColor: .withColorStudio(.red, shade: .shade40))

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsReportCardViewModel(title: "ORDERS",
                                                             leadingTitle: "Total Orders",
                                                             leadingValue: "145",
                                                             leadingDelta: "+36%",
                                                             leadingDeltaColor: .withColorStudio(.green, shade: .shade50),
                                                             trailingTitle: "Average Order Value",
                                                             trailingValue: "$57,99",
                                                             trailingDelta: "-16%",
                                                             trailingDeltaColor: .withColorStudio(.red, shade: .shade40))

    // MARK: Private data

    /// Order stats for the current selected time period
    ///
    @Published private var currentOrderStats: OrderStatsV4 = {
        fakeOrderStats(with: fakeCurrentOrderTotals())
    }()

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4 = {
        fakeOrderStats(with: fakePreviousOrderTotals())
    }()
}

// MARK: - Fake data

/// Extension with fake data. This can be removed once we fetch real data from the API.
///
private extension AnalyticsHubViewModel {
    static func fakeCurrentOrderTotals() -> OrderStatsV4Totals {
        OrderStatsV4Totals(totalOrders: 3,
                           totalItemsSold: 5,
                           grossRevenue: 800,
                           couponDiscount: 0,
                           totalCoupons: 0,
                           refunds: 0,
                           taxes: 0,
                           shipping: 0,
                           netRevenue: 800,
                           totalProducts: 2,
                           averageOrderValue: 266)
    }

    static func fakePreviousOrderTotals() -> OrderStatsV4Totals {
        OrderStatsV4Totals(totalOrders: 2,
                           totalItemsSold: 8,
                           grossRevenue: 1000,
                           couponDiscount: 0,
                           totalCoupons: 0,
                           refunds: 0,
                           taxes: 0,
                           shipping: 0,
                           netRevenue: 900,
                           totalProducts: 2,
                           averageOrderValue: 500)
    }

    static func fakeOrderStats(with totals: OrderStatsV4Totals) -> OrderStatsV4 {
        OrderStatsV4(siteID: 12345, granularity: .daily, totals: totals, intervals: [])
    }
}
