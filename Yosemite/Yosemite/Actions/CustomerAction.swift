import Foundation

/// Defines the `actions` supported by the `CustomerStore`.
///
public enum CustomerAction: Action {
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
