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

    let filterActionTitle = Localization.filterActionTitle

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
            return Localization.rowTitleOrderStatus
        case .dateRange:
            return Localization.rowTitleDateRange
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
            let options: [OrderDateRangeFilterEnum] = [.any, .today, .last2Days, .thisWeek, .thisMonth, .custom(start: nil, end: nil)]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .ordersDateRange(options: options),
                                       selectedValue: filters.dateRange)
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
    var description: String {
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
}

// MARK: - Constants
private extension FilterOrderListViewModel {
    enum Localization {
        static let filterActionTitle = NSLocalizedString("Show Orders", comment: "Button title for applying filters to a list of orders.")
    }
}

private extension FilterOrderListViewModel.OrderListFilter {
    enum Localization {
        static let rowTitleOrderStatus = NSLocalizedString("Order Status", comment: "Row title for filtering orders by order status.")
        static let rowTitleDateRange = NSLocalizedString("Date Range", comment: "Row title for filtering orders by date range.")
    }
}
