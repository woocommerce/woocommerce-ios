import protocol WooFoundation.WooAnalyticsEventPropertyType
import enum Yosemite.SalesChannelFilter

extension WooAnalyticsEvent {
    enum OrdersFilter {
        /// Event property keys.
        private enum Key {
            static let status = "status"
            static let dateRange = "date_range"
            static let product = "product"
            static let customer = "customer"
            static let salesChannel = "sales_channel"
        }

        /// Tracked upon filtering orders
        static func onFilterOrders(filters: FilterOrderListViewModel.Filters) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [Key.status: filters.orderStatus?.analyticsDescription,
                                                                        Key.dateRange: filters.dateRange?.analyticsDescription,
                                                                        Key.product: filters.product?.analyticsDescription,
                                                                        Key.customer: filters.customer?.analyticsDescription,
                                                                        Key.salesChannel: filters.salesChannel?.analyticsDescription]
            return WooAnalyticsEvent(statName: .ordersListFilter,
                                     properties: properties.compactMapValues { $0 })
        }
    }
}

fileprivate extension SalesChannelFilter {
    var analyticsDescription: String? {
        switch self {
        case .pointOfSale:
            return "pos"
        case .webCheckout:
            return "checkout"
        case .wpAdmin:
            return "admin"
        case .any:
            return nil
        }
    }
}
