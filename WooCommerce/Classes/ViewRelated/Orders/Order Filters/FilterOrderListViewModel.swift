import UIKit
import Yosemite

/// `FilterListViewModel` for filtering a list of orders.
final class FilterOrderListViewModel: FilterListViewModel {
    typealias Criteria = Filters

    /// Aggregates the filter values that can be updated in the Filter Order UI.
    struct Filters: Equatable {
        let orderStatus: OrderStatusEnum?
        let dateRange: OrderDateRangeFilterEnum?

        let numberOfActiveFilters: Int

        init() {
            orderStatus = nil
            dateRange = nil
            numberOfActiveFilters = 0
        }

        init(orderStatus: OrderStatusEnum?,
             dateRange: OrderDateRangeFilterEnum?,
             numberOfActiveFilters: Int) {
            self.orderStatus = orderStatus
            self.dateRange = dateRange
            self.numberOfActiveFilters = numberOfActiveFilters
        }
    }

    let filterActionTitle = NSLocalizedString("Show Orders", comment: "Button title for applying filters to a list of orders.")

    let filterTypeViewModels: [FilterTypeViewModel]

    private let orderStatusFilterViewModel: FilterTypeViewModel
    private let dateRangeFilterViewModel: FilterTypeViewModel

    /// - Parameters:
    ///   - filters: the filters to be applied initially.
    init(filters: Filters) {
        orderStatusFilterViewModel = OrderListFilter.orderStatus.createViewModel(filters: filters)
        dateRangeFilterViewModel = OrderListFilter.dateRange.createViewModel(filters: filters)

        filterTypeViewModels = [orderStatusFilterViewModel, dateRangeFilterViewModel]
    }

    var criteria: Filters {
        let orderStatus = orderStatusFilterViewModel.selectedValue as? OrderStatusEnum ?? nil
        let dateRange = dateRangeFilterViewModel.selectedValue as? OrderDateRangeFilterEnum ?? nil
        let numberOfActiveFilters = filterTypeViewModels.numberOfActiveFilters
        return Filters(orderStatus: orderStatus,
                       dateRange: dateRange,
                       numberOfActiveFilters: numberOfActiveFilters)
    }

    func clearAll() {
        let clearedOrderStatus: OrderStatusEnum? = nil
        orderStatusFilterViewModel.selectedValue = clearedOrderStatus

        let clearedDateRange: OrderDateRangeFilterEnum? = nil
        dateRangeFilterViewModel.selectedValue = clearedDateRange
    }
}

extension FilterOrderListViewModel {
    /// Rows listed in the order they appear on screen
    ///
    enum OrderListFilter {
        case orderStatus
        case dateRange
    }
}

private extension FilterOrderListViewModel.OrderListFilter {
    var title: String {
        switch self {
        case .orderStatus:
            return NSLocalizedString("Order Status", comment: "Row title for filtering orders by order status.")
        case .dateRange:
            return NSLocalizedString("Date range", comment: "Row title for filtering orders by date range.")
        }
    }
}

extension FilterOrderListViewModel.OrderListFilter {
    func createViewModel(filters: FilterOrderListViewModel.Filters) -> FilterTypeViewModel {
        switch self {
        case .orderStatus:
            let options: [OrderStatusEnum?] = [nil, .pending, .processing, .onHold, .failed, .cancelled, .completed, .refunded]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.orderStatus)
        case .dateRange:
            let options: [OrderDateRangeFilterEnum?] = [nil, .today, .last2Days, .thisWeek, .thisMonth, .custom]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.dateRange)
        }
    }
}

// MARK: - FilterType conformance
extension OrderStatusEnum: FilterType {
    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .pending:
            return NSLocalizedString("Pending", comment: "Display label for pending order status.")
        case .processing:
            return NSLocalizedString("Processing", comment: "Display label for processing order status.")
        case .onHold:
            return NSLocalizedString("On hold", comment: "Display label for on hold order status.")
        case .failed:
            return NSLocalizedString("Failed", comment: "Display label for failed order status.")
        case .cancelled:
            return NSLocalizedString("Cancelled", comment: "Display label for cancelled order status.")
        case .completed:
            return NSLocalizedString("Completed", comment: "Display label for completed order status.")
        case .refunded:
            return NSLocalizedString("Refunded", comment: "Display label for refunded order status.")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }

    var isActive: Bool {
        return true
    }
}

// MARK: - FilterType conformance
extension OrderDateRangeFilterEnum: FilterType {
    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .today:
            return NSLocalizedString("Today", comment: "Label for one of the filters in order date range")
        case .last2Days:
            return NSLocalizedString("Last 2 Days", comment: "Label for one of the filters in order date range")
        case .thisWeek:
            return NSLocalizedString("This Week", comment: "Label for one of the filters in order date range")
        case .thisMonth:
            return NSLocalizedString("This Month", comment: "Label for one of the filters in order date range")
        case .custom:
            return NSLocalizedString("Custom Range", comment: "Label for one of the filters in order date range")
        }
    }

    var isActive: Bool {
        return true
    }
}
