import Foundation
import Yosemite

final class BookingFiltersViewModel: FilterListViewModel {
    let filterActionTitle = Localization.filterActionTitle
    let filterTypeViewModels: [FilterTypeViewModel]
    let shouldShowHistory = false
    let source = FilterSource.booking

    private let teamMemberFilterViewModel: FilterTypeViewModel
    private let productFilterViewModel: FilterTypeViewModel
    private let customerFilterViewModel: FilterTypeViewModel
    private let attendanceStatusFilterViewModel: FilterTypeViewModel
    private let dateTimeFilterViewModel: FilterTypeViewModel


    init(filter: Filters,
         siteID: Int64) {
        teamMemberFilterViewModel = BookingListFilter.teamMember(siteID: siteID).createViewModel(filters: filter)
        productFilterViewModel = BookingListFilter.product(siteID: siteID).createViewModel(filters: filter)
        customerFilterViewModel = BookingListFilter.customer(siteID: siteID).createViewModel(filters: filter)
        attendanceStatusFilterViewModel = BookingListFilter.attendanceStatus.createViewModel(filters: filter)
        dateTimeFilterViewModel = BookingListFilter.dateTime.createViewModel(filters: filter)

        filterTypeViewModels = [
            teamMemberFilterViewModel,
            productFilterViewModel,
            attendanceStatusFilterViewModel,
            customerFilterViewModel,
            dateTimeFilterViewModel
        ]
    }

    var criteria: Filters {
        let teamMembers = (teamMemberFilterViewModel.selectedValue as? MultipleFilterSelection)?.items as? [BookingTeamMemberFilter] ?? []
        let products = (productFilterViewModel.selectedValue as? MultipleFilterSelection)?.items as? [BookingProductFilter] ?? []
        let customers = (customerFilterViewModel.selectedValue as? MultipleFilterSelection)?.items as? [BookingCustomerFilter] ?? []
        let attendanceStatus = attendanceStatusFilterViewModel.selectedValue as? BookingAttendanceStatus
        let dateRange = dateTimeFilterViewModel.selectedValue as? BookingDateRangeFilter
        let numberOfActiveFilters = filterTypeViewModels.numberOfActiveFilters

        return Filters(teamMembers: teamMembers,
                       products: products,
                       attendanceStatus: attendanceStatus,
                       customers: customers,
                       dateRange: dateRange,
                       numberOfActiveFilters: numberOfActiveFilters)
    }

    func retrieveFilterHistory() async throws -> [Filters] {
        // TODO: Implement when booking filter history is available
        return []
    }

    func applyPastFilter(_ filter: Filters) {
        // TODO: Implement when booking filter history is available
    }

    func saveSelectedFilterToHistory(_ filter: Filters) {
        // TODO: Implement when booking filter history storage is available
    }

    func removeFilterFromHistory(_ filter: Filters) {
        // TODO: Implement when booking filter history storage is available
    }

    func clearAllFilterHistory() {
        // TODO: Implement when booking filter history storage is available
    }

    func clearAll() {
        teamMemberFilterViewModel.selectedValue = BookingTeamMemberFilter?.none
        productFilterViewModel.selectedValue = BookingProductFilter?.none
        customerFilterViewModel.selectedValue = CustomerFilter?.none
        attendanceStatusFilterViewModel.selectedValue = BookingAttendanceStatus?.none
        dateTimeFilterViewModel.selectedValue = BookingDateRangeFilter?.none
    }

    typealias Criteria = Filters

    struct Filters: Equatable, HumanReadable {

        let teamMembers: [BookingTeamMemberFilter]
        let products: [BookingProductFilter]
        let attendanceStatus: BookingAttendanceStatus?
        let customers: [BookingCustomerFilter]
        let dateRange: BookingDateRangeFilter?

        let numberOfActiveFilters: Int

        init() {
            teamMembers = []
            products = []
            attendanceStatus = nil
            customers = []
            dateRange = nil
            numberOfActiveFilters = 0
        }

        init(teamMembers: [BookingTeamMemberFilter],
             products: [BookingProductFilter],
             attendanceStatus: BookingAttendanceStatus?,
             customers: [BookingCustomerFilter],
             dateRange: BookingDateRangeFilter?,
             numberOfActiveFilters: Int) {
            self.teamMembers = teamMembers
            self.products = products
            self.attendanceStatus = attendanceStatus
            self.customers = customers
            self.dateRange = dateRange
            self.numberOfActiveFilters = numberOfActiveFilters
        }

        var readableString: String {
            var readable: [String] = teamMembers.map { $0.name } +
            products.map { $0.name }
            if let attendanceStatus {
                readable.append(attendanceStatus.localizedTitle)
            }

            readable += customers.map { $0.name }

            if let dateRange {
                readable.append(dateRange.description)
            }

            return readable.joined(separator: ", ")
        }

        var bookingFilters: BookingFilters {
            BookingFilters(
                productIDs: products.map { $0.productID },
                customerIDs: customers.map { $0.customerID },
                resourceIDs: teamMembers.map { $0.resourceID },
                startDateBefore: dateRange?.endDate?.ISO8601Format(),
                startDateAfter: dateRange?.startDate?.ISO8601Format(),
                attendanceStatus: attendanceStatus?.rawValue,
            )
        }
    }
}

extension BookingFiltersViewModel {
    /// Rows listed in the order they appear on screen
    ///
    enum BookingListFilter {
        case teamMember(siteID: Int64)
        case product(siteID: Int64)
        case attendanceStatus
        case customer(siteID: Int64)
        case dateTime
    }
}

private extension BookingFiltersViewModel.BookingListFilter {
    var title: String {
        switch self {
        case .teamMember:
            return Localization.rowTitleTeamMember
        case .product:
            return Localization.rowTitleProduct
        case .customer:
            return Localization.rowTitleCustomer
        case .attendanceStatus:
            return Localization.rowTitleAttendanceStatus
        case .dateTime:
            return Localization.rowTitleDateTime
        }
    }
}

extension BookingFiltersViewModel.BookingListFilter {
    func createViewModel(filters: BookingFiltersViewModel.Filters) -> FilterTypeViewModel {
        switch self {
        case .teamMember(let siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .bookingResource(siteID: siteID),
                                       selectedValue: MultipleFilterSelection(items: filters.teamMembers))
        case .product(let siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .bookableProduct(siteID: siteID),
                                       selectedValue: MultipleFilterSelection(items: filters.products))
        case .customer(let siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .bookingCustomers(siteID: siteID),
                                       selectedValue: MultipleFilterSelection(items: filters.customers))
        case .attendanceStatus:
            let options: [BookingAttendanceStatus?] = [nil, .attended, .unattended]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.attendanceStatus)
        case .dateTime:
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .bookingDateTime,
                                       selectedValue: filters.dateRange)
        }
    }
}

// MARK: - FilterType conformance
extension BookingTeamMemberFilter: FilterType {
    var description: String { name }
    var isActive: Bool { true }
}

extension BookingAttendanceStatus: FilterType {
    var description: String { localizedTitle }

    var isActive: Bool {
        switch self {
        case .attended, .unattended:
            return true
        case .unknown:
            return false
        }
    }
}

extension BookingProductFilter: FilterType {
    /// The user-facing description of the filter value.
    var description: String { name }

    /// Whether the filter is set to a non-empty value.
    var isActive: Bool { true }
}

extension BookingCustomerFilter: FilterType {
    /// The user-facing description of the filter value.
    var description: String { name }

    /// Whether the filter is set to a non-empty value.
    var isActive: Bool { true }
}

extension BookingDateRangeFilter: FilterType {
    var description: String {
        if let startDate, let endDate {
            [
                startDate.formatted(date: .abbreviated, time: .omitted),
                endDate.formatted(date: .abbreviated, time: .omitted)
            ].joined(separator: " - ")
        } else if let startDate {
            String.localizedStringWithFormat(
                Localization.dateRangeFrom,
                startDate.formatted(date: .abbreviated, time: .shortened)
            )
        } else if let endDate {
            String.localizedStringWithFormat(
                Localization.dateRangeUntil,
                endDate.formatted(date: .abbreviated, time: .shortened)
            )
        } else {
            Localization.dateRangeAny
        }
    }

    var isActive: Bool {
        startDate != nil || endDate != nil
    }

    private enum Localization {
        static let dateRangeFrom = NSLocalizedString(
            "bookingFiltersViewModel.dateRangeFilter.from",
            value: "From %1$@",
            comment: "Description for booking date range filter with only start date. " +
            "Placeholder is a date. Reads as: From October 27, 2025."
        )
        static let dateRangeUntil = NSLocalizedString(
            "bookingFiltersViewModel.dateRangeFilter.until",
            value: "Until %1$@",
            comment: "Description for booking date range filter with only end date. " +
            "Placeholder is a date. Reads as: Until October 27, 2025."
        )
        static let dateRangeAny = NSLocalizedString(
            "bookingFiltersViewModel.dateRangeFilter.any",
            value: "Any",
            comment: "Description for booking date range filter with no dates selected"
        )
    }
}

// MARK: - Constants
private extension BookingFiltersViewModel {
    enum Localization {
        static let filterActionTitle = NSLocalizedString(
            "bookingFilters.filterActionTitle",
            value: "Show bookings",
            comment: "Button title for applying filters to a list of bookings.")
    }
}

private extension BookingFiltersViewModel.BookingListFilter {
    enum Localization {
        static let rowTitleTeamMember = NSLocalizedString(
            "bookingFilters.rowTitleTeamMember",
            value: "Team Member",
            comment: "Row title for filtering bookings by team member.")

        static let rowTitleProduct = NSLocalizedString(
            "bookingFilters.rowTitleService",
            value: "Service",
            comment: "Row title for filtering bookings by product.")

        static let rowTitleCustomer = NSLocalizedString(
            "bookingFilters.rowCustomer",
            value: "Customer",
            comment: "Row title for filtering bookings by customer.")

        static let rowTitleAttendanceStatus = NSLocalizedString(
            "bookingFilters.rowTitleAttendanceStatus",
            value: "Attendance Status",
            comment: "Row title for filtering bookings by attendance status.")

        static let rowTitlePaymentStatus = NSLocalizedString(
            "bookingFilters.rowTitlePaymentStatus",
            value: "Payment Status",
            comment: "Row title for filtering bookings by payment status.")

        static let rowTitleDateTime = NSLocalizedString(
            "bookingFilters.rowTitleDateTime",
            value: "Date & time",
            comment: "Row title for filtering bookings by date range.")
    }
}
