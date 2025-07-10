import Foundation
import Codegen

/// Represents a list of available Shipping Label Config info for the WooCommerce Shipping extension.
///
public struct WooShippingConfigResponse: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let config: WooShippingConfig

    public init(config: WooShippingConfig) {
        self.config = config
    }
}

public struct WooShippingConfig: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    /// The remote ID of the site that owns this shipping label config info.
    public let siteID: Int64

    /// Shipments of this order.
    public let shipments: [WooShippingShipment]

    /// Holds info about the shipping labels
    public let shippingLabelData: WooShippingLabelData?

    public init(siteID: Int64,
                shipments: [WooShippingShipment],
                shippingLabelData: WooShippingLabelData?) {
        self.siteID = siteID
        self.shipments = shipments
        self.shippingLabelData = shippingLabelData
    }

    private enum CodingKeys: String, CodingKey {
        case shipments
        case shippingLabelData
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw WooShippingConfigDecodingError.missingSiteID
        }

        guard let orderID = decoder.userInfo[.orderID] as? Int64 else {
            throw WooShippingConfigDecodingError.missingOrderID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shipments: [WooShippingShipment] = {
            guard let shipmentsString = try? container.decodeIfPresent(String.self, forKey: .shipments),
                  let data = shipmentsString.data(using: .utf8) else {
                return []
            }

            guard let contents = (try? JSONDecoder().decode(WooShippingShipments.self, from: data)) else {
                return []
            }

            var shipments = [WooShippingShipment]()
            for (index, items) in contents {
                shipments.append(WooShippingShipment(siteID: siteID, orderID: orderID, index: index, items: items))
            }
            return shipments
        }()

        let shippingLabelData = try container.decodeIfPresent(WooShippingLabelData.self, forKey: .shippingLabelData)
        self.init(siteID: siteID,
                  shipments: shipments,
                  shippingLabelData: shippingLabelData)
    }
}

public struct WooShippingLabelData: Decodable, Equatable {
    /// Labels purchased for the current order
    public let currentOrderLabels: [ShippingLabel]

    public init(currentOrderLabels: [ShippingLabel]) {
        self.currentOrderLabels = currentOrderLabels
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let currentOrderLabels = try container.decodeIfPresent([ShippingLabel].self, forKey: .currentOrderLabels) ?? []
        self.init(currentOrderLabels: currentOrderLabels)
    }

    private enum CodingKeys: String, CodingKey {
        case currentOrderLabels
    }
}

// MARK: - Decoding Errors
//
enum WooShippingConfigDecodingError: Error {
    case missingSiteID
    case missingOrderID
}
