import Foundation

/// Defines the `actions` supported by the `CustomerStore`.
///
public enum CustomerAction: Action {
    /// Synchronizes the Customers matching the specified criteria. When syncing the first page number it resets (deletes) all the stores objects.
    /// Note that the synchronized Customer objects only contain the most relevant data (name, email) which makes this action convenient for showing
    /// a Customers preview, e.g. in a list. If you want to retrieve all customers information please use `retrieveCustomer` action.
    ///
    /// - Parameter onCompletion: called when sync completes.
    ///
    case synchronizeLightCustomersData(
        siteID: Int64,
        pageNumber: Int,
        pageSize: Int,
        onCompletion: (Result<Void, Error>) -> Void)

    /// Searches for Customers by keyword. Currently, only searches by name.
    ///
    ///- `siteID`: The site for which we will perform the search.
    ///- `keyword`: Keyword to perform the search. Only searches by name.
    ///- `onCompletion`: Invoked when the operation finishes.
    ///     - `result.success([Customer])`:  On success, the Customers found will be loaded in Core Data.
    ///     - `result.failure(Error)`: Error fetching data
    case searchCustomers(
        siteID: Int64,
        keyword: String,
        onCompletion: (Result<[Customer], Error>) -> Void)

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
}
