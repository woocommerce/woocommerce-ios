import Foundation
import Yosemite


// MARK: - OrderStatusKey Helper Methods
//
extension OrderStatusKey {

    /// Returns a collection of all of the known Order Status
    ///
    static var knownStatus: [OrderStatusKey] {
        return [.pending, .processing, .onHold, .failed, .cancelled, .completed, .refunded]
    }
}
