import Foundation

/// Defines the `actions` supported by the `CustomerStore`.
///
public enum CustomerAction: Action {

    /// Retrieves Customers from a site
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
