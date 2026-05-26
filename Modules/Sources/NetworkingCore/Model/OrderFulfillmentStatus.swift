import Foundation
import Codegen

/// Represents the fulfillment status of a CIAB order.
/// Parsed from the `_fulfillment_status` order meta key.
public enum OrderFulfillmentStatus: String, Codable, Sendable, GeneratedFakeable {
    case fulfilled = "fulfilled"
    case partiallyFulfilled = "partially_fulfilled"
    case unfulfilled = "unfulfilled"
    case noFulfillments = "no_fulfillments"

    /// Non-CIAB site, legacy order, or meta key not present.
    case unknown
}
