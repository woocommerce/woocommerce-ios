import Foundation

public enum FeedbackType: String, Codable {
    /// Identifier for the general inApp feedback survey
    ///
    case general

    /// identifier for the products m3 beta feedback survey
    ///
    case productsM3
}
