import Foundation

/// Defines the `actions` supported by the `WCAnalyticsCustomerStore`.
///
public enum WCAnalyticsCustomerAction: Action {

    /// Retrieves a collection of WCAnalyticsCustomer from a site
    ///
    ///- `siteID`: The site for which customers should be fetched.
    ///- `keyword`: Keyword to perform the search for WCAnalyticsCustomer to be fetched.
    ///- `onCompletion`: Invoked when the operation finishes.
    ///     - `result.success(Customer)`: The Customer object
    ///     - `result.failure(Error)`: Error fetching Customer
    case retrieveCustomers(
        siteID: Int64,
        keyword: String,
        onCompletion: (Result<[WCAnalyticsCustomer], Error>) -> Void)
}
