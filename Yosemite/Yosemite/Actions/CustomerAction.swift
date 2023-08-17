import Foundation

/// The type of filter when searching for customers.
public enum CustomerSearchFilter: String, Equatable, CaseIterable {
    case all
    case name
    case username
    case email
}

/// Defines the `actions` supported by the `CustomerStore`.
///
public enum CustomerAction: Action {
    /// Synchronizes the Customers matching the specified criteria. When syncing the first page number it resets (deletes) all the stored objects.
    /// Note that the synchronized Customer objects only contain the most relevant data (name, email) which makes this action convenient for showing
    /// a Customers preview, e.g. in a list. If you want to retrieve all customers information please use `retrieveCustomer` action.
    ///
    /// - Parameter onCompletion: called when sync completes. Returns true if there are results synced
    ///
    case synchronizeLightCustomersData(
        siteID: Int64,
        pageNumber: Int,
        pageSize: Int,
        onCompletion: (Result<Bool, Error>) -> Void)

    /// Searches for Customers by keyword. Currently, only searches by name.
    ///
    ///- `siteID`: The site for which we will perform the search.
    ///- `pageNumber`: The number of the page you want to load.
    ///- `pageSize`: The size of the page you want to load.
    ///- `keyword`: Keyword to perform the search.
    ///- `filter`: Filter to perform the search.
    ///- `retrieveFullCustomersData`: If `true`, retrieves all customers data one by one after the search request. It will be removed once
    ///  `betterCustomerSelectionInOrder` is finished for performance reasons.
    ///- `onCompletion`: Invoked when the operation finishes.
    ///     - `result.success()`:  On success.
    ///     - `result.failure(Error)`: Error fetching data
    case searchCustomers(
        siteID: Int64,
        pageNumber: Int,
        pageSize: Int,
        keyword: String,
        retrieveFullCustomersData: Bool,
        filter: CustomerSearchFilter,
        onCompletion: (Result<(), Error>) -> Void)

    /// Retrieves a single Customer from a site
    ///
    ///- `siteID`: The site for which customers should be fetched.
    ///- `customerID`: ID of the Customer to be fetched.
    ///- `onCompletion`: Invoked when the operation finishes.
    ///     - `result.success(Customer)`: The Customer object
    ///     - `result.failure(Error)`: Error fetching Customer
    case retrieveCustomer(
        siteID: Int64,
        customerID: Int64,
        onCompletion: (Result<Customer, Error>) -> Void)


    /// Deletes all customers for the given site
    ///
    ///- `siteID`: The site for which customers should be delete.
    ///- `onCompletion`: Invoked when the operation finishes.
    case deleteAllCustomers(siteID: Int64, onCompletion: () -> Void)
}
