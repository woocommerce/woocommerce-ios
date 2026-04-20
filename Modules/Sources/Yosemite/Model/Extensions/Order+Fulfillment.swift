import Foundation
import Networking

// MARK: - Fulfillment Helpers

public extension Order {
    /// The most recent fulfillment date across all fulfilled entries, if any.
    var latestDateFulfilled: Date? {
        fulfillments
            .filter { $0.isFulfilled }
            .compactMap { $0.dateFulfilled }
            .max()
    }
}
