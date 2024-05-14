import protocol WooFoundation.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    enum OrdersFilter {
        /// Event property keys.
        private enum Key {
            static let status = "status"
            static let dateRange = "date_range"
            static let product = "product"
            static let customer = "customer"
        }

        /// Tracked upon filtering orders
        static func onFilterOrders(filters: FilterOrderListViewModel.Filters) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [Key.status: filters.orderStatus?.analyticsDescription,
                                                                        Key.dateRange: filters.dateRange?.analyticsDescription,
                                                                        Key.product: filters.product?.analyticsDescription,
                                                                        Key.customer: filters.customer?.analyticsDescription]
            return WooAnalyticsEvent(statName: .ordersListFilter,
                                     properties: properties.compactMapValues { $0 })
        }
    }
}
