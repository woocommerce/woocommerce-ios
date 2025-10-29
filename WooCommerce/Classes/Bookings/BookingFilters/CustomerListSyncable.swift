import Foundation
import Yosemite

/// Syncable implementation for customer filtering
struct CustomerListSyncable: ListSyncable {
    typealias StorageType = StorageCustomer
    typealias ModelType = Customer
    typealias ListFilterType = BookingCustomerFilter

    let siteID: Int64

    var title: String { Localization.title }

    var emptyStateMessage: String { Localization.noCustomersFound }

    var emptyItemTitlePlaceholder: String? { Localization.emptyItemTitlePlaceholder }

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
    }
}
