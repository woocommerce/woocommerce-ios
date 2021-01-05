import Foundation

public enum FeedbackType: String, Codable {
    /// Identifier for the general inApp feedback survey
    ///
    case general

    /// identifier for the products m4 beta feedback survey
    ///
    case productsM4

    /// identifier for the shipping labels m1 feedback survey
    ///
    case shippingLabelsRelease1
}
