import Foundation
import Codegen

/// Represents a Shipping Label Creation Eligibility response for an order.
///
public struct ShippingLabelCreationEligibilityResponse: Equatable, GeneratedFakeable {
    /// Whether the order is eligible for shipping label creation.
    public let isEligible: Bool

    /// The reason if an order is **not** eligible for shipping label creation.
    /// Returned when `isEligible` is false.
    public let reason: String?

    public init(isEligible: Bool, reason: String?) {
        self.isEligible = isEligible
        self.reason = reason
    }
}

// MARK: Decodable
extension ShippingLabelCreationEligibilityResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let isEligible = try container.decode(Bool.self, forKey: .isEligible)
        let reason = try container.decodeIfPresent(String.self, forKey: .reason)

        self.init(isEligible: isEligible, reason: reason)
    }

    private enum CodingKeys: String, CodingKey {
        case isEligible = "is_eligible"
        case reason
    }
}
