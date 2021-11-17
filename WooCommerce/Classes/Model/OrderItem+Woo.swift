import Foundation
import Yosemite


// MARK: - OrderItem Helper Methods
//
extension OrderItem {
    /// Returns the variant if it exists
    ///
    var productOrVariationID: Int64 {
        if variationID == 0 {
            return productID
        }

        return variationID
    }
}
