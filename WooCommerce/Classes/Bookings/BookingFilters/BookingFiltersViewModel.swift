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
    private let paymentStatusFilterViewModel: FilterTypeViewModel
    private let dateTimeFilterViewModel: FilterTypeViewModel


    init(filter: Filters,
         siteID: Int64) {
        teamMemberFilterViewModel = BookingListFilter.teamMember(siteID: siteID).createViewModel(filters: filter)
        productFilterViewModel = BookingListFilter.product(siteID: siteID).createViewModel(filters: filter)
        customerFilterViewModel = BookingListFilter.customer(siteID: siteID).createViewModel(filters: filter)
        attendanceStatusFilterViewModel = BookingListFilter.attendanceStatus.createViewModel(filters: filter)
        paymentStatusFilterViewModel = BookingListFilter.paymentStatus.createViewModel(filters: filter)
        dateTimeFilterViewModel = BookingListFilter.dateTime.createViewModel(filters: filter)

        filterTypeViewModels = [
            teamMemberFilterViewModel,
            productFilterViewModel,
            attendanceStatusFilterViewModel,
            paymentStatusFilterViewModel,
            customerFilterViewModel,
            dateTimeFilterViewModel
        ]
    }

    var criteria: Filters {
        let teamMember = teamMemberFilterViewModel.selectedValue as? BookingResource
        let product = productFilterViewModel.selectedValue as? BookingProductFilter
        let customer = customerFilterViewModel.selectedValue as? CustomerFilter
        let attendanceStatus = attendanceStatusFilterViewModel.selectedValue as? BookingAttendanceStatus
        let paymentStatus = paymentStatusFilterViewModel.selectedValue as? BookingStatus
        let dateRange = dateTimeFilterViewModel.selectedValue as? BookingDateRangeFilter
        let numberOfActiveFilters = filterTypeViewModels.numberOfActiveFilters

        return Filters(teamMember: teamMember,
                       product: product,
                       attendanceStatus: attendanceStatus,
                       paymentStatus: paymentStatus,
                       customer: customer,
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
        teamMemberFilterViewModel.selectedValue = BookingResource?.none
        productFilterViewModel.selectedValue = BookingProductFilter?.none
        customerFilterViewModel.selectedValue = CustomerFilter?.none
        attendanceStatusFilterViewModel.selectedValue = BookingAttendanceStatus?.none
        paymentStatusFilterViewModel.selectedValue = BookingStatus?.none
        dateTimeFilterViewModel.selectedValue = BookingDateRangeFilter?.none
    }

    typealias Criteria = Filters

    struct Filters: Equatable, HumanReadable {

        let teamMember: BookingResource?
        let product: BookingProductFilter?
        let attendanceStatus: BookingAttendanceStatus?
        let paymentStatus: BookingStatus?
        let customer: CustomerFilter?
        let dateRange: BookingDateRangeFilter?

        let numberOfActiveFilters: Int

        init() {
            teamMember = nil
            product = nil
            attendanceStatus = nil
            paymentStatus = nil
            customer = nil
            dateRange = nil
            numberOfActiveFilters = 0
        }

        init(teamMember: BookingResource?,
             product: BookingProductFilter?,
             attendanceStatus: BookingAttendanceStatus?,
             paymentStatus: BookingStatus?,
             customer: CustomerFilter?,
             dateRange: BookingDateRangeFilter?,
             numberOfActiveFilters: Int) {
            self.teamMember = teamMember
            self.product = product
            self.attendanceStatus = attendanceStatus
            self.paymentStatus = paymentStatus
            self.customer = customer
            self.dateRange = dateRange
            self.numberOfActiveFilters = numberOfActiveFilters
        }

        var readableString: String {
            var readable: [String] = []
            if let teamMember {
                readable.append(teamMember.name)
            }
            if let product {
                readable.append(product.name)
            }
            if let attendanceStatus {
                readable.append(attendanceStatus.localizedTitle)
            }
            if let paymentStatus {
                readable.append(paymentStatus.localizedTitle)
            }
            if let customer {
                readable.append(customer.description)
            }
            if let dateRange {
                readable.append(dateRange.description)
            }

            return readable.joined(separator: ", ")
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
        case paymentStatus
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
        case .paymentStatus:
            return Localization.rowTitlePaymentStatus
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
                                       selectedValue: filters.teamMember)
        case .product(let siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .bookableProduct(siteID: siteID),
                                       selectedValue: filters.product)
        case .customer(let siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .customer(siteID: siteID, source: .booking),
                                       selectedValue: filters.customer)
        case .attendanceStatus:
            let options: [BookingAttendanceStatus?] = [nil, .booked, .checkedIn, .cancelled, .noShow]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.attendanceStatus)
        case .paymentStatus:
            let options: [BookingStatus?] = [nil, .complete, .paid, .unpaid, .cancelled, .pendingConfirmation, .confirmed]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.paymentStatus)
        case .dateTime:
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .bookingDateTime,
                                       selectedValue: filters.dateRange)
        }
    }
}

// MARK: - FilterType conformance
extension BookingResource: FilterType {
    var description: String { name }
    var isActive: Bool { true }
}

extension BookingAttendanceStatus: FilterType {
    var description: String { localizedTitle }

    var isActive: Bool {
        switch self {
        case .booked, .checkedIn, .cancelled, .noShow:
            return true
        case .unknown:
            return false
        }
    }
}

extension BookingStatus: FilterType {
    var description: String { localizedTitle }

    var isActive: Bool {
        switch self {
        case .complete, .paid, .unpaid, .cancelled, .pendingConfirmation, .confirmed:
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

extension BookingDateRangeFilter: FilterType {
    var description: String {
        // TODO: Format dates nicely when implementing date range selector
        if let startDate = startDate, let endDate = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        } else if let startDate = startDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return NSLocalizedString(
                "bookingDateRangeFilter.from",
                value: "From \(formatter.string(from: startDate))",
                comment: "Description for booking date range filter with only start date")
        } else if let endDate = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return NSLocalizedString(
                "bookingDateRangeFilter.until",
                value: "Until \(formatter.string(from: endDate))",
                comment: "Description for booking date range filter with only end date")
        } else {
            return NSLocalizedString(
                "bookingDateRangeFilter.any",
                value: "Any",
                comment: "Description for booking date range filter with no dates selected")
        }
    }

    var isActive: Bool {
        startDate != nil || endDate != nil
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
            "bookingFilters.rowTitleProduct",
            value: "Service / Event",
            comment: "Row title for filtering bookings by product.")

        static let rowTitleCustomer = NSLocalizedString(
            "bookingFilters.rowTitleCustomer",
            value: "Customer name",
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
