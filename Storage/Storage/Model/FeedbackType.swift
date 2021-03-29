import Foundation

public enum FeedbackType: String, Codable {
    /// Identifier for the general inApp feedback survey
    ///
    case general

    /// Identifier for the Products Variations.
    ///
    case productsVariations

    /// identifier for the shipping labels m1 feedback survey
    ///
    case shippingLabelsRelease1
}
