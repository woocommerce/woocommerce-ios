extension WooAnalyticsEvent {
    enum OrdersFilter {
        /// Event property keys.
        private enum Key {
            static let status = "status"
            static let dateRange = "date_range"
            static let product = "product"
        }

        /// Tracked upon filtering orders
        static func onFilterOrders(filters: FilterOrderListViewModel.Filters) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [Key.status: filters.orderStatus?.analyticsDescription,
                                                                        Key.dateRange: filters.dateRange?.analyticsDescription,
                                                                        Key.product: filters.product?.analyticsDescription]
            return WooAnalyticsEvent(statName: .ordersListFilter,
                                     properties: properties.compactMapValues { $0 })
        }
    }
}
