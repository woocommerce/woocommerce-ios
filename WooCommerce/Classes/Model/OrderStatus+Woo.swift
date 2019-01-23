import Foundation
import Yosemite


// MARK: - OrderStatus Helper Methods
//
extension OrderStatus {

    /// Returns a collection of all of the known Order Status
    ///
    static var knownStatus: [OrderStatus] {
        return [.pending, .processing, .onHold, .failed, .cancelled, .completed, .refunded]
    }
}
