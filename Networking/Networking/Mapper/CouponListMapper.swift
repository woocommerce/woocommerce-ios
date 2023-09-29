/// Mapper: `Coupon` List
///
struct CouponListMapper: Mapper {
    /// Site we're parsing `Coupon`s for
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Coupon endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[Coupon]`.
    ///
    func map(response: Data) throws -> [Coupon] {
        let decoder = Coupon.decoder
        if hasDataEnvelope(in: response) {
            let coupons = try decoder.decode(Envelope<[Coupon]>.self, from: response).data
            return coupons.map { $0.copy(siteID: siteID) }
        } else {
            return try decoder.decode([Coupon].self, from: response)
                .map { $0.copy(siteID: siteID) }
        }
    }
}
