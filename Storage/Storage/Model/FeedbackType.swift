import Foundation

public enum FeedbackType: String, Codable {
    /// Identifier for the general inApp feedback survey
    ///
    case general

    /// Identifier for the coupon management feedback survey
    ///
    case couponManagement

    /// Identifier for the order form shipping lines feedback survey
    ///
    case orderFormShippingLines
}
