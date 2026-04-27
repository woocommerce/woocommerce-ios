import UIKit
import Yosemite
import Experiments
import WooFoundation

/// `FilterListViewModel` for filtering a list of orders.
final class FilterOrderListViewModel: FilterListViewModel {
    typealias Criteria = Filters

    /// Aggregates the filter values that can be updated in the Filter Order UI.
    struct Filters: Equatable, HumanReadable {
        let orderStatus: [OrderStatusEnum]?
        let dateRange: OrderDateRangeFilter?
        let product: FilterOrdersByProduct?
        let customer: CustomerFilter?
        let salesChannel: SalesChannelFilter?

        let numberOfActiveFilters: Int

        init() {
            orderStatus = nil
            dateRange = nil
            product = nil
            customer = nil
            salesChannel = nil
            numberOfActiveFilters = 0
        }

        init(orderStatus: [OrderStatusEnum]?,
             dateRange: OrderDateRangeFilter?,
             product: FilterOrdersByProduct?,
             customer: CustomerFilter?,
             salesChannel: SalesChannelFilter?,
             numberOfActiveFilters: Int) {
            self.orderStatus = orderStatus
            self.dateRange = dateRange
            self.product = product
            self.customer = customer
            self.salesChannel = salesChannel
            self.numberOfActiveFilters = numberOfActiveFilters
        }

        var readableString: String {
            var readable: [String] = []
            if let orderStatus, !orderStatus.isEmpty {
                readable = orderStatus.map { $0.rawValue.capitalized }
            }
            if let dateRange {
                readable.append(dateRange.description)
            }
            if let product {
                readable.append(product.name)
            }
            if let customer {
                readable.append(customer.description)
            }

            if let salesChannel {
                readable.append(salesChannel.description)
            }

            return readable.joined(separator: ", ")
        }
    }

    let filterActionTitle = Localization.filterActionTitle

    let filterTypeViewModels: [FilterTypeViewModel]

    let shouldShowHistory: Bool

    let source = FilterSource.orders

    private let orderStatusFilterViewModel: FilterTypeViewModel
    private let dateRangeFilterViewModel: FilterTypeViewModel
    private let productFilterViewModel: FilterTypeViewModel
    private let customerFilterViewModel: FilterTypeViewModel
    private let salesChannelFilterViewModel: FilterTypeViewModel

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    /// - Parameters:
    ///   - filters: the filters to be applied initially.
    ///   - allowedStatuses: the statuses that will be shown in the filter list.
    ///   - siteID: current selected site ID
    ///   - featureFlagService: feature flag service
    ///   - stores: stores manager
    init(filters: Filters,
         allowedStatuses: [OrderStatus],
         siteID: Int64,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        orderStatusFilterViewModel = OrderListFilter.orderStatus.createViewModel(filters: filters, allowedStatuses: allowedStatuses)
        dateRangeFilterViewModel = OrderListFilter.dateRange.createViewModel(filters: filters, allowedStatuses: allowedStatuses)
        productFilterViewModel = OrderListFilter.product(siteID: siteID).createViewModel(filters: filters, allowedStatuses: allowedStatuses)
        customerFilterViewModel = OrderListFilter.customer(siteID: siteID).createViewModel(filters: filters, allowedStatuses: allowedStatuses)
        salesChannelFilterViewModel = OrderListFilter.salesChannel.createViewModel(filters: filters, allowedStatuses: allowedStatuses)

        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics

        shouldShowHistory = featureFlagService.isFeatureFlagEnabled(.filterHistoryOnOrderAndProductLists)
        var allFilterViewModels = [orderStatusFilterViewModel,
                                   dateRangeFilterViewModel,
                                   customerFilterViewModel,
                                   productFilterViewModel]

        if featureFlagService.isFeatureFlagEnabled(.pointOfSaleOrdersi2) {
            allFilterViewModels.append(salesChannelFilterViewModel)
        }

        filterTypeViewModels = allFilterViewModels
    }

    var criteria: Filters {
        let orderStatus = orderStatusFilterViewModel.selectedValue as? [OrderStatusEnum] ?? nil
        let dateRange = dateRangeFilterViewModel.selectedValue as? OrderDateRangeFilter ?? nil
        let product = productFilterViewModel.selectedValue as? FilterOrdersByProduct ?? nil
        let customer = customerFilterViewModel.selectedValue as? CustomerFilter ?? nil
        let salesChannel = salesChannelFilterViewModel.selectedValue as? SalesChannelFilter ?? nil
        let numberOfActiveFilters = filterTypeViewModels.numberOfActiveFilters
        return Filters(orderStatus: orderStatus,
                       dateRange: dateRange,
                       product: product,
                       customer: customer,
                       salesChannel: salesChannel,
                       numberOfActiveFilters: numberOfActiveFilters)
    }

    @MainActor
    func retrieveFilterHistory() async throws -> [Filters] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadOrderFilterHistory(siteID: siteID, onCompletion: { result in
                switch result {
                case .success(let history):
                    let filters = history.map { item in
                        Filters(orderStatus: item.orderStatusesFilter,
                                dateRange: item.dateRangeFilter,
                                product: item.productFilter,
                                customer: item.customerFilter,
                                salesChannel: item.salesChannelFilter,
                                numberOfActiveFilters: item.numberOfActiveFilters())
                    }
                    continuation.resume(returning: filters)
                case .failure(let error):
                    DDLogError("⛔️ Error loading filter history for orders: \(error)")
                    continuation.resume(throwing: error)
                }
            }))
        }
    }

    func applyPastFilter(_ filter: Filters) {
        orderStatusFilterViewModel.selectedValue = filter.orderStatus
        dateRangeFilterViewModel.selectedValue = filter.dateRange
        productFilterViewModel.selectedValue = filter.product
        customerFilterViewModel.selectedValue = filter.customer
        salesChannelFilterViewModel.selectedValue = filter.salesChannel
        analytics.track(event: .FilterHistory.trackPastFilterApplied(source: source))
    }

    func saveSelectedFilterToHistory(_ filter: Criteria) {
        let settings = StoredOrderSettings.Setting(siteID: siteID,
                                                   orderStatusesFilter: filter.orderStatus,
                                                   dateRangeFilter: filter.dateRange,
                                                   productFilter: filter.product,
                                                   customerFilter: filter.customer,
                                                   salesChannelFilter: filter.salesChannel)
        stores.dispatch(AppSettingsAction.upsertOrderFilterHistory(filter: settings, onCompletion: { error in
            if let error {
                DDLogError("⛔️ Error saving filter history: \(error)")
            }
        }))
    }

    func removeFilterFromHistory(_ filter: Criteria) {
        analytics.track(event: .FilterHistory.trackPastFilterRemoved(source: source))
        let settings = StoredOrderSettings.Setting(siteID: siteID,
                                                   orderStatusesFilter: filter.orderStatus,
                                                   dateRangeFilter: filter.dateRange,
                                                   productFilter: filter.product,
                                                   customerFilter: filter.customer,
                                                   salesChannelFilter: filter.salesChannel)
        stores.dispatch(AppSettingsAction.removeFromOrderFilterHistory(filter: settings, onCompletion: { error in
            if let error {
                DDLogError("⛔️ Error removing from filter history: \(error)")
            }
        }))
    }

    func clearAllFilterHistory() {
        analytics.track(event: .FilterHistory.trackFilterHistoryCleared(source: source))
        stores.dispatch(AppSettingsAction.resetOrderFilterHistory(siteID: siteID, onCompletion: { error in
            if let error {
                DDLogError("⛔️ Error clearing all filter history: \(error)")
            }
        }))
    }

    func clearAll() {
        let clearedOrderStatus: OrderStatusEnum? = nil
        orderStatusFilterViewModel.selectedValue = clearedOrderStatus

        let clearedDateRange: OrderDateRangeFilter? = nil
        dateRangeFilterViewModel.selectedValue = clearedDateRange

        let clearedProduct: FilterOrdersByProduct? = nil
        productFilterViewModel.selectedValue = clearedProduct

        let clearedCustomer: CustomerFilter? = nil
        customerFilterViewModel.selectedValue = clearedCustomer

        let clearSalesChannel: SalesChannelFilter? = nil
        salesChannelFilterViewModel.selectedValue = clearSalesChannel
    }
}

extension FilterOrderListViewModel {
    /// Rows listed in the order they appear on screen
    ///
    enum OrderListFilter {
        case orderStatus
        case dateRange
        case product(siteID: Int64)
        case customer(siteID: Int64)
        case salesChannel
    }
}

private extension FilterOrderListViewModel.OrderListFilter {
    var title: String {
        switch self {
        case .orderStatus:
            return Localization.rowTitleOrderStatus
        case .dateRange:
            return Localization.rowTitleDateRange
        case .product:
            return Localization.rowTitleProduct
        case .customer:
            return Localization.rowCustomer
        case .salesChannel:
            return Localization.rowSalesChannel
        }
    }
}

extension FilterOrderListViewModel.OrderListFilter {
    func createViewModel(filters: FilterOrderListViewModel.Filters, allowedStatuses: [OrderStatus]) -> FilterTypeViewModel {
        switch self {
        case .orderStatus:
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .ordersStatuses(allowedStatuses: allowedStatuses),
                                       selectedValue: filters.orderStatus)
        case .dateRange:
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .ordersDateRange,
                                       selectedValue: filters.dateRange)
        case .product(let siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .products(siteID: siteID),
                                       selectedValue: filters.product)
        case .customer(let siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .customer(siteID: siteID),
                                       selectedValue: filters.customer)
        case .salesChannel:
            let salesChannelOptions: [SalesChannelFilter] = [.any, .pointOfSale, .webCheckout, .wpAdmin]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: salesChannelOptions),
                                       selectedValue: filters.salesChannel)
        }
    }
}

// MARK: - FilterType conformance
extension OrderStatusEnum: FilterType {
    var isActive: Bool {
        return true
    }

    /// Returns the localized text version of the Enum
    ///
    var description: String { localizedName }
}

extension Array: FilterType where Element == OrderStatusEnum {
    var isActive: Bool {
        return true
    }

    /// Returns the localized text version of the array
    ///
    var description: String {
        if self.isEmpty {
            return NSLocalizedString("Any", comment: "Display label for all order statuses selected in Order Filters")
        }
        else if self.count == 1 {
            return self.first?.description ?? ""
        }
        else {
            return "\(self.count)"
        }
    }
}

extension FilterOrdersByProduct: FilterType {
    /// The user-facing description of the filter value.
    var description: String { name }

    /// Whether the filter is set to a non-empty value.
    var isActive: Bool { true }
}

// MARK: - Constants
private extension FilterOrderListViewModel {
    enum Localization {
        static let filterActionTitle = NSLocalizedString(
            "filterOrderListViewModel.OrderListFilter.filterActionTitle",
            value: "Show Orders",
            comment: "Button title for applying filters to a list of orders.")
    }
}

private extension FilterOrderListViewModel.OrderListFilter {
    enum Localization {
        static let rowTitleOrderStatus = NSLocalizedString(
            "filterOrderListViewModel.OrderListFilter.rowTitleOrderStatus",
            value: "Order Status",
            comment: "Row title for filtering orders by order status.")

        static let rowTitleDateRange = NSLocalizedString(
            "filterOrderListViewModel.OrderListFilter.rowTitleDateRange",
            value: "Date Range",
            comment: "Row title for filtering orders by date range.")

        static let rowTitleProduct = NSLocalizedString(
            "filterOrderListViewModel.OrderListFilter.rowTitleProduct",
            value: "Product",
            comment: "Row title for filtering orders by Product.")

        static let rowCustomer = NSLocalizedString(
            "filterOrderListViewModel.OrderListFilter.rowCustomer",
            value: "Customer",
            comment: "Row title for filtering orders by customer.")

        static let rowSalesChannel = NSLocalizedString(
            "filterOrderListViewModel.OrderListFilter.rowSalesChannel",
            value: "Sales Channel",
            comment: "Row title for filtering orders by sales channel.")
    }
}

extension CustomerFilter: FilterType {
    /// The user-facing description of the filter value.
    var description: String {
        let fullName = [firstName, lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if fullName.isNotEmpty {
            return fullName
        } else if let email,
                  email.isNotEmpty {
            return email
        } else if let username,
                  username.isNotEmpty {
            return username
        } else {
            return "id: " + String(id)
        }
    }

    /// Whether the filter is set to a non-empty value.
    var isActive: Bool { true }
}

extension SalesChannelFilter: FilterType {
    var description: String {
        switch self {
        case .pointOfSale:
            return NSLocalizedString(
                "salesChannelFilter.row.pos.description",
                value: "Point of Sale",
                comment: "Description for the Sales channel filter option, when selecting 'Point of Sale' orders")
        case .webCheckout:
            return NSLocalizedString(
                "salesChannelFilter.row.webCheckout.description",
                value: "Web Checkout",
                comment: "Description for the Sales channel filter option, when selecting 'Web Checkout' orders")
        case .wpAdmin:
            return NSLocalizedString(
                "salesChannelFilter.row.wpAdmin.description",
                value: "WP-Admin",
                comment: "Description for the Sales channel filter option, when selecting 'WP-Admin' orders")
        case .any:
            return NSLocalizedString(
                "salesChannelFilter.row.any.description",
                value: "Any",
                comment: "Description for the Sales channel filter option, when selecting 'Any' order")
        }
    }

    var isActive: Bool {
        switch self {
        case .pointOfSale, .webCheckout, .wpAdmin:
            return true
        case .any:
            return false
        }
    }
}
