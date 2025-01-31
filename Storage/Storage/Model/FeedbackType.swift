import Foundation

public enum FeedbackType: String, Codable {
    /// Identifier for the general inApp feedback survey
    ///
    case general

    /// Identifier for the order form shipping lines feedback survey
    ///
    case orderFormShippingLines
}
