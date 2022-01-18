import Foundation

/// Mapper: `CouponReport`
///
struct CouponReportListMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[CouponReport]`.
    ///
    func map(response: Data) throws -> [CouponReport] {
        let decoder = JSONDecoder()
        let reports = try decoder.decode(CouponReportsEnvelope.self, from: response).reports
        return reports
    }
}


/// CouponReportsEnvelope Disposable Entity:
/// Load Coupon endpoint returns the coupon in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct CouponReportsEnvelope: Decodable {
    let reports: [CouponReport]

    private enum CodingKeys: String, CodingKey {
        case reports = "data"
    }
}
