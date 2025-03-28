import Foundation
import Codegen

/// Response after updating shipments of an order
///
public struct WooShippingUpdateShipmentResponse: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let siteID: Int64
    public let orderID: Int64
    public let shipments: [String: [WooShippingShipment]]

    public init(siteID: Int64,
                orderID: Int64,
                shipments: [String: [WooShippingShipment]]) {
        self.siteID = siteID
        self.orderID = orderID
        self.shipments = shipments
    }

    private enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw WooShippingUpdateShipmentDecodingError.missingSiteID
        }

        guard let orderID = decoder.userInfo[.orderID] as? Int64 else {
            throw WooShippingUpdateShipmentDecodingError.missingOrderID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shipments: [String: [WooShippingShipment]] = {
            guard let shipmentsString = try? container.decodeIfPresent(String.self, forKey: .data),
                  let data = shipmentsString.data(using: .utf8) else {
                return [:]
            }

            return (try? JSONDecoder().decode([String: [WooShippingShipment]].self, from: data)) ?? [:]
        }()

        self.init(siteID: siteID,
                  orderID: orderID,
                  shipments: shipments)
    }
}

// MARK: - Decoding Errors
//
enum WooShippingUpdateShipmentDecodingError: Error {
    case missingSiteID
    case missingOrderID
}
