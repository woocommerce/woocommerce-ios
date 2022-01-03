import Foundation

/// Defines the `actions` supported by the `CouponStore`.
///
public enum CouponAction: Action {

    /// Retrieves and stores Coupons for a site
    ///
    /// - `siteID`: the site for which coupons should be fetched.
    /// - `pageNumber`: page of results based on the `pageSize` provided. 1-indexed.
    /// - `pageSize`: number of results per page.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success(Bool)`: value indicates whether there are further pages to retrieve.
    ///     - `result.failure(Error)`: error indicates issues syncing the specified page.
    ///
    case synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int,
                            onCompletion: (Result<Bool, Error>) -> Void)
}
