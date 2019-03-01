import Foundation
import Yosemite


// MARK: - OrderStatusEnum Helper Methods
//
extension OrderStatusEnum {

    /// Returns a collection of all of the known Order Status
    ///
    static var knownStatus: [OrderStatusEnum] {
        return [.pending, .processing, .onHold, .failed, .cancelled, .completed, .refunded]
    }
}
