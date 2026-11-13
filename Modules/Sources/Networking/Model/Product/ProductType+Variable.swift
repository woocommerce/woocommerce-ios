import Foundation

public extension ProductType {

    /// Whether this product type has variations (variable or variable subscription).
    ///
    var isVariable: Bool {
        self == .variable || self == .variableSubscription
    }
}
