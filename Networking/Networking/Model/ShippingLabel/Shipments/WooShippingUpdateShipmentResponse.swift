import Foundation
import Codegen

/// Response after updating shipments of an order
///
public struct WooShippingUpdateShipmentResponse: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let shipments: WooShippingShipments

    public init(shipments: WooShippingShipments) {
        self.shipments = shipments
    }

    private enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shipments: WooShippingShipments = {
            guard let shipmentsString = try? container.decodeIfPresent(String.self, forKey: .data),
                  let data = shipmentsString.data(using: .utf8) else {
                return [:]
            }

            return (try? JSONDecoder().decode(WooShippingShipments.self, from: data)) ?? [:]
        }()

        self.init(shipments: shipments)
    }
}
