import Foundation

public enum FeedbackType: String, Codable {
    /// Identifier for the general inApp feedback survey
    ///
    case general

    /// Identifier for the Products M5: Linked Products, Downloadable Files, Trashing.
    ///
    case productsM5

    /// identifier for the shipping labels m1 feedback survey
    ///
    case shippingLabelsRelease1
}
