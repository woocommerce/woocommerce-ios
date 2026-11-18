struct StoreOrderListHeaderState: Equatable {
    let activeFilterCount: Int
    let lastUpdatedText: String?
    let banner: Banner

    var title: String {
        activeFilterCount == 0 ? OrderListLocalization.allOrdersHeaderTitle : OrderListLocalization.filteredOrdersHeaderTitle
    }

    var filterButtonTitle: String {
        OrderListLocalization.filterButtonTitle(activeFilterCount: activeFilterCount)
    }

    enum Banner: Equatable {
        case none
        case error(title: String, message: String)
        case currencyUnavailable
    }
}
