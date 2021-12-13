import Foundation
import Codegen

/// Represents the response when polling for a shipping label status.
///
/// The status endpoint can return a `ShippingLabelPurchase` (for pending or failed purchases) or `ShippingLabel` (for a successful purchase).
///
public enum ShippingLabelStatusPollingResponse: Decodable {
    case pending(ShippingLabelPurchase)
    case purchased(ShippingLabel)

    /// The status of pending or purchased shipping label.
    ///
    public var status: ShippingLabelStatus {
        switch self {
        case .pending(let purchase):
            return purchase.status
        case .purchased(let label):
            return label.status
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let data = try container.decode(ShippingLabel.self)
            self = .purchased(data)
        } catch {
            let data = try container.decode(ShippingLabelPurchase.self)
            self = .pending(data)
        }
    }

    /// Returns the associated `ShippingLabel` for a purchased shipping label
    ///
    public func getPurchasedLabel() -> ShippingLabel? {
        switch self {
        case .pending:
            return nil
        case .purchased(let label):
            return label
        }
    }
}
