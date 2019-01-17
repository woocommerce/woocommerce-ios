import Foundation
import Yosemite


// MARK: - OrderStatus Helper Methods
//
extension OrderStatus {

    /// Returns a collection of all of the known Order Status
    ///
    static var knownStatus: [OrderStatus] {
        // .onHold is an existing status but we don't want it to display.
        return [.pending, .processing, .failed, .cancelled, .completed, .refunded]
    }
}
