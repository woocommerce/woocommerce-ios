import Foundation

public extension ProductType {

    /// Whether this product type represents a subscription (simple or variable subscription).
    ///
    var isSubscription: Bool {
        self == .subscription || self == .variableSubscription
    }
}
