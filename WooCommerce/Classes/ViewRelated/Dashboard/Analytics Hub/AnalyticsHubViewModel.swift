import Foundation
import Yosemite

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

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
    @Published private var currentOrderStats: OrderStatsV4? = nil

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4? = nil
}
