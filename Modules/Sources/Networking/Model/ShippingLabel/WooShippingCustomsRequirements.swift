import Codegen
import Foundation

/// Describes whether a shipping label route needs EU product identifiers.
public struct WooShippingCustomsRequirements: Equatable, GeneratedFakeable {
    public let euProductIDsRequired: Bool

    public init(euProductIDsRequired: Bool) {
        self.euProductIDsRequired = euProductIDsRequired
    }
}

extension WooShippingCustomsRequirements: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(euProductIDsRequired: try container.decode(Bool.self, forKey: .euProductIDsRequired))
    }

    private enum CodingKeys: String, CodingKey {
        case euProductIDsRequired = "eu_product_ids_required"
    }
}
