import Foundation
import Yosemite


// MARK: - OrderItemRefund Helper Methods
//
extension OrderItemRefund {
    /// Returns the variant if it exists
    ///
    var productOrVariationID: Int64 {
        if variationID == 0 {
            return productID
        }

        return variationID
    }
}
