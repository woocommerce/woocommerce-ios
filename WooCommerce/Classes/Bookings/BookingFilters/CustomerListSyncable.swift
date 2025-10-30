import Foundation
import Yosemite

/// Syncable implementation for customer filtering
struct CustomerListSyncable: ListSyncable {
    typealias StorageType = StorageCustomer
    typealias ModelType = Customer
    typealias ListFilterType = BookingCustomerFilter

    let siteID: Int64

    let title = Localization.title

    let emptyStateMessage = Localization.noCustomersFound
    let emptyItemTitlePlaceholder: String? = Localization.emptyItemTitlePlaceholder

    let searchConfiguration: ListSearchConfiguration? = ListSearchConfiguration(
        searchPrompt: Localization.searchPrompt,
        emptySearchTitle: Localization.noCustomersFound,
        emptySearchDescription: Localization.emptySearchDescription
    )

    let selectionDisabledMessage: String? = Localization.selectionDisabledMessage

    // MARK: - ResultsController Configuration

    func createPredicate() -> NSPredicate {
        NSPredicate(format: "siteID == %lld", siteID)
    }

    func createSortDescriptors() -> [NSSortDescriptor] {
        [NSSortDescriptor(key: "customerID", ascending: false)]
    }

    // MARK: - Sync Configuration

    func createSyncAction(
        pageNumber: Int,
        pageSize: Int,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) -> Action {
        CustomerAction.synchronizeLightCustomersData(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            orderby: .name,
            order: .asc,
            filterEmpty: .email,
            onCompletion: completion
        )
    }

    /// Creates the action to search items with keyword
    func createSearchAction(keyword: String, pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action {
        CustomerAction.searchCustomers(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            orderby: .name,
            order: .asc,
            keyword: keyword,
            retrieveFullCustomersData: false,
            filter: .all,
            filterEmpty: .email,
            onCompletion: completion
        )
    }

    /// Creates the predicate for filtering search results
    /// - Returns: nil because customer search handles filtering directly
    func createSearchPredicate(keyword: String) -> NSPredicate? {
        nil
    }

    // MARK: - Display Configuration

    func displayName(for item: Customer) -> String {
        guard let firstName = item.firstName, firstName.isNotEmpty,
              let lastName = item.lastName, lastName.isNotEmpty else {
            return ""
        }
        return [firstName, lastName].joined(separator: " ")
    }

    /// Returns the description for an item
    func description(for item: Customer) -> String? {
        item.email
    }

    func selectionEnabled(for item: Customer) -> Bool {
        item.customerID > 0
    }

    func filterItem(for item: Customer) -> BookingCustomerFilter {
        let name: String = {
            if let firstName = item.firstName, let lastName = item.lastName {
                return [firstName, lastName].joined(separator: " ")
            }
            return item.username ?? item.email
        }()
        return BookingCustomerFilter(customerID: item.customerID, name: name)
    }
}

private extension CustomerListSyncable {
    enum Localization {
        static let title = NSLocalizedString(
            "bookingCustomerSelectorView.title",
            value: "Customer",
            comment: "Title of the booking customer selector view"
        )
        static let noCustomersFound = NSLocalizedString(
            "bookingCustomerSelectorView.noCustomersFound",
            value: "No customer found",
            comment: "Text on the empty view of the booking customer selector view"
        )
        static let emptyItemTitlePlaceholder = NSLocalizedString(
            "bookingCustomerSelectorView.emptyItemTitlePlaceholder",
            value: "No name",
            comment: "Title of the booking customer selector view"
        )
        static let searchPrompt = NSLocalizedString(
            "bookingCustomerSelectorView.searchPrompt",
            value: "Search customer",
            comment: "Prompt in the search bar of the booking customer selector view"
        )
        static let emptySearchDescription = NSLocalizedString(
            "bookingCustomerSelectorView.emptySearchDescription",
            value: "Try adjusting your search term to see more results",
            comment: "Message on the empty search result view of the booking customer selector view"
        )
        static let selectionDisabledMessage = NSLocalizedString(
            "bookingCustomerSelectorView.selectionDisabledMessage",
            value: "This user is a guest, and guests can’t be used for filtering bookings.",
            comment: "Error message when selecting guest customer in booking filtering"
        )
    }
}
