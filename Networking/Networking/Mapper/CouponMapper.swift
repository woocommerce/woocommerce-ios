import Foundation

/// Mapper: `Coupon`
///
struct CouponMapper: Mapper {
    /// Site we're parsing `Coupon` for
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Coupon endpoints.
    ///
    let siteID: Int64

    /// JSON decoder appropriate for `Coupon` responses.
    ///
    private static let decoder: JSONDecoder = {
        let couponDecoder = JSONDecoder()
        couponDecoder.keyDecodingStrategy = .convertFromSnakeCase
        couponDecoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        return couponDecoder
    }()

    /// (Attempts) to convert a dictionary into `Coupon`.
    ///
    func map(response: Data) throws -> Coupon {
        let coupon = try Self.decoder.decode(CouponEnvelope.self, from: response).coupon
        return coupon.copy(siteId: siteID)
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
