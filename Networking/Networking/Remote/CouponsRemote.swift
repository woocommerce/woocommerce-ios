import Foundation

/// Protocol for `CouponsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol CouponsRemoteProtocol {
    func loadAllCoupons(for siteID: Int64,
                        pageNumber: Int,
                        pageSize: Int,
                        completion: @escaping (Result<[Coupon], Error>) -> ())

    func searchCoupons(for siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int,
                       completion: @escaping (Result<[Coupon], Error>) -> ())

    func retrieveCoupon(for siteID: Int64,
                        couponID: Int64,
                        completion: @escaping (Result<Coupon, Error>) -> Void)

    func deleteCoupon(for siteID: Int64,
                      couponID: Int64,
                      completion: @escaping (Result<Coupon, Error>) -> Void)

    func updateCoupon(_ coupon: Coupon, completion: @escaping (Result<Coupon, Error>) -> Void)

    func createCoupon(_ coupon: Coupon, completion: @escaping (Result<Coupon, Error>) -> Void)

    func loadCouponReport(for siteID: Int64,
                          couponID: Int64,
                          from startDate: Date,
                          completion: @escaping (Result<CouponReport, Error>) -> Void)
}


/// Coupons: Remote endpoints
///
public final class CouponsRemote: Remote, CouponsRemoteProtocol {
    // MARK: - Get Coupons

    /// Retrieves all of the `Coupon`s from the API.
    ///
    /// - Parameters:
    ///     - siteID: The site for which we'll fetch coupons.
    ///     - pageNumber: The page number of the coupon list to be fetched.
    ///     - pageSize: The maximum number of coupons to be fetched for the current page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllCoupons(for siteID: Int64,
                               pageNumber: Int = Default.pageNumber,
                               pageSize: Int = Default.pageSize,
                               completion: @escaping (Result<[Coupon], Error>) -> ()) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize)
        ]

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.coupons,
                                     parameters: parameters)

        let mapper = CouponListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    public func searchCoupons(for siteID: Int64,
                              keyword: String,
                              pageNumber: Int,
                              pageSize: Int,
                              completion: @escaping (Result<[Coupon], Error>) -> ()) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.keyword: String(keyword)
        ]

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.coupons,
                                     parameters: parameters)

        let mapper = CouponListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a `Coupon`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the coupon.
    ///     - couponID: ID of the Coupon that will be retrieved.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func retrieveCoupon(for siteID: Int64,
                               couponID: Int64,
                               completion: @escaping (Result<Coupon, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.coupons + "/\(couponID)")

        let mapper = CouponMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    // MARK: - Delete Coupon

    /// Deletes a `Coupon`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll delete the coupon.
    ///     - couponID: ID of the Coupon that will be deleted.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func deleteCoupon(for siteID: Int64,
                             couponID: Int64,
                             completion: @escaping (Result<Coupon, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .delete,
                                     siteID: siteID,
                                     path: Path.coupons + "/\(couponID)",
                                     parameters: [ParameterKey.force: true])

        let mapper = CouponMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    // MARK: - Update Coupon

    /// Updates a `Coupon`.
    ///
    /// - Parameters:
    ///     - coupon: The coupon to be updated remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateCoupon(_ coupon: Coupon, completion: @escaping (Result<Coupon, Error>) -> Void) {
        do {
            let parameters = try coupon.toDictionary()
            let couponID = coupon.couponID
            let siteID = coupon.siteID
            let path = Path.coupons + "/\(couponID)"
            let request = JetpackRequest(wooApiVersion: .mark3, method: .put, siteID: siteID, path: path, parameters: parameters)
            let mapper = CouponMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Create coupon

    /// Creates a `Coupon`.
    ///
    /// - Parameters:
    ///     - coupon: The coupon to be created remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createCoupon(_ coupon: Coupon, completion: @escaping (Result<Coupon, Error>) -> Void) {
        do {
            let parameters = try coupon.toDictionary()
            let siteID = coupon.siteID
            let path = Path.coupons
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
            let mapper = CouponMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Load coupon report
    /// Loads the analytics report for a specific coupon from a given site.
    ///
    /// - Parameters:
    ///     - siteID: The site from which we'll fetch the analytics report.
    ///     - couponID: The coupon for which we'll fetch the analytics report.
    ///     - startDate: The start of the date range for which we'll fetch the analytics report.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadCouponReport(for siteID: Int64,
                                 couponID: Int64,
                                 from startDate: Date,
                                 completion: @escaping (Result<CouponReport, Error>) -> Void) {
        let dateFormatter = ISO8601DateFormatter()
        let formattedTime = dateFormatter.string(from: startDate)

        let parameters: [String: Any] = [
            ParameterKey.coupons: [couponID],
            ParameterKey.after: formattedTime
        ]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.couponReports,
                                     parameters: parameters)

        let mapper = CouponReportListMapper()

        enqueue(request, mapper: mapper, completion: { result in
            switch result {
            case .success(let couponReports):
                if let report = couponReports.first {
                    completion(.success(report))
                } else {
                    completion(.failure(CouponsRemoteError.noAnalyticsReportsFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}

// MARK: - Constants
//
public extension CouponsRemote {
    enum CouponsRemoteError: Error {
        case noAnalyticsReportsFound
    }

    enum Default {
        public static let pageSize = 25
        public static let pageNumber = 1
    }

    private enum Path {
        static let coupons = "coupons"
        static let couponReports = "reports/coupons"
    }

    private enum ParameterKey {
        static let page = "page"
        static let perPage = "per_page"
        static let force = "force"
        static let coupons = "coupons"
        static let keyword = "search"
        static let after = "after"
    }
}
