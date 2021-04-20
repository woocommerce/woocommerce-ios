import Foundation

/// Coupons: Remote endpoints
///
public final class CouponsRemote: Remote {
    // MARK: - Get Coupons

    /// Retrieves all of the `Coupon`s from the API.
    ///
    /// - Parameters:
    ///     - siteID
    ///     - pageNumber:
    ///     - pageSize:
    ///     - completion:
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
}

// MARK: - Constants
//
public extension CouponsRemote {
    enum Default {
        public static let pageSize = 25
        public static let pageNumber = 1
    }

    private enum Path {
        static let coupons = "coupons"
    }

    private enum ParameterKey {
        static let page = "page"
        static let perPage = "per_page"
    }
}
