import Foundation

/// Defines the `actions` supported by the `CouponStore`.
///
public enum CouponAction: Action {

    /// Retrieves and stores Coupons for a site
    ///
    /// - `siteID`: the site for which coupons should be fetched.
    /// - `siteURL`: Address of the site to fetch coupons for.
    /// - `pageNumber`: page of results based on the `pageSize` provided. 1-indexed.
    /// - `pageSize`: number of results per page.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success(Bool)`: value indicates whether there are further pages to retrieve.
    ///     - `result.failure(Error)`: error indicates issues syncing the specified page.
    ///
    case synchronizeCoupons(siteID: Int64,
                            siteURL: String,
                            pageNumber: Int,
                            pageSize: Int,
                            onCompletion: (Result<Bool, Error>) -> Void)

    /// Deletes a coupon for a site given its ID
    ///
    /// - `siteID`: ID of the site that the coupon belongs to.
    /// - `siteURL`: Address of the site that the coupon belongs to.
    /// - `couponID`: ID of the coupon to be deleted.
    /// - `onCompletion`: invoked when the deletion finishes.
    ///
    case deleteCoupon(siteID: Int64,
                      siteURL: String,
                      couponID: Int64,
                      onCompletion: (Result<Void, Error>) -> Void)

    /// Updates a coupon for a site given its ID and returns the updated coupon if the request succeeds.
    ///
    /// - `coupon`: the coupon to be updated.
    /// - `siteURL`: Address of the site that the coupon belongs to.
    /// - `siteTimezone`: the timezone configured on the site (also know as local time of the site).
    /// - `onCompletion`: invoked when the update finishes.
    ///
    case updateCoupon(_ coupon: Coupon,
                      siteURL: String,
                      siteTimezone: TimeZone?,
                      onCompletion: (Result<Coupon, Error>) -> Void)

    /// Creates a coupon for a site given its ID and returns the created coupon if the request succeeds.
    ///
    /// - `coupon`: the coupon to be created.
    /// - `siteURL`: Address of the site to create the coupon for.
    /// - `siteTimezone`: the timezone configured on the site (also know as local time of the site).
    /// - `onCompletion`: invoked when the creation finishes.
    ///
    case createCoupon(_ coupon: Coupon,
                      siteURL: String,
                      siteTimezone: TimeZone?,
                      onCompletion: (Result<Coupon, Error>) -> Void)

    /// Loads analytics report for a coupon with the specified coupon ID and site ID.
    ///
    /// - `siteID`: ID of the site that the coupon belongs to.
    /// - `siteURL`: Address of the site from which we'll fetch the analytics report.
    /// - `couponID`: ID of the coupon to load analytics report for.
    /// - `startDate`: the start of the date range to fetch report for.
    /// - `onCompletion`: invoked when the creation finishes.
    ///
    case loadCouponReport(siteID: Int64,
                          siteURL: String,
                          couponID: Int64,
                          startDate: Date,
                          onCompletion: (Result<CouponReport, Error>) -> Void)

    /// Search Coupons matching a given keyword for a site
    ///
    /// - `siteID`: the site for which coupons should be fetched.
    /// - `siteURL`: address of the site to search coupons for.
    /// - `keyword`: the keyword to match the results with.
    /// - `pageNumber`: page of results based on the `pageSize` provided. 1-indexed.
    /// - `pageSize`: number of results per page.
    /// - `onCompletion`: invoked when the search finishes.
    ///
    case searchCoupons(siteID: Int64,
                       siteURL: String,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int,
                       onCompletion: (Result<Void, Error>) -> Void)

    /// Retrieve a Coupon for a site given the coupon ID
    ///
    /// - `siteID`: the site for which coupons should be fetched.
    /// - `siteURL`: address of the site that the coupon belongs to.
    /// - `couponID`: ID of the coupon to be retrieved.
    /// - `onCompletion`: invoked upon completion.
    ///
    case retrieveCoupon(siteID: Int64,
                        siteURL: String,
                        couponID: Int64,
                        onCompletion: (Result<Coupon, Error>) -> Void)
}
