import Foundation

extension Coupon {
    /// JSON decoder appropriate for `Coupon` responses.
    ///
    static let decoder: JSONDecoder = {
        let couponDecoder = JSONDecoder()
        couponDecoder.keyDecodingStrategy = .convertFromSnakeCase
        couponDecoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        return couponDecoder
    }()
}
