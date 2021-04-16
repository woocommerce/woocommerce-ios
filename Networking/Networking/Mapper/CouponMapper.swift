import Foundation

/// Mapper: `Coupon`
///
struct CouponMapper: Mapper {
    /// Site we're parsing `Coupon` for
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Coupon endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `Coupon`.
    ///
    func map(response: Data) throws -> Coupon {
        let coupon = try Coupon.decoder.decode(CouponEnvelope.self, from: response).coupon
        return coupon.copy(siteID: siteID)
    }
}


/// CouponEnvelope Disposable Entity:
/// Load Coupon endpoint returns the coupon in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct CouponEnvelope: Decodable {
    let coupon: Coupon

    private enum CodingKeys: String, CodingKey {
        case coupon = "data"
    }
}
