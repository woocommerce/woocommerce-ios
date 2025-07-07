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

    /// Shipments of this order. The keys are the ids of the shipment.
    public let shipments: WooShippingShipments

    /// Holds info about the shipping labels
    public let shippingLabelData: WooShippingLabelData?

    public init(siteID: Int64,
                shipments: WooShippingShipments,
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

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shipments: WooShippingShipments = {
            guard let shipmentsString = try? container.decodeIfPresent(String.self, forKey: .shipments),
                  let data = shipmentsString.data(using: .utf8) else {
                return [:]
            }

            return (try? JSONDecoder().decode(WooShippingShipments.self, from: data)) ?? [:]
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

    /// Contains destination addresses
    public let storedData: StoredData?

    public init(
        currentOrderLabels: [ShippingLabel],
        storedData: StoredData? = nil
    ) {
        self.currentOrderLabels = currentOrderLabels
        self.storedData = storedData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let storedData = try container.decodeIfPresent(StoredData.self, forKey: .storedData)
        let decodedOrderLabels = try container.decodeIfPresent([ShippingLabel].self, forKey: .currentOrderLabels) ?? []

        /// Inject destination addresses into labels if present
        let orderLabels: [ShippingLabel]

        let destinations = storedData?.selectedDestinations
        let origins = storedData?.selectedOrigins

        if destinations?.isEmpty == false || origins?.isEmpty == false {
            orderLabels = WooShippingLabelData.mapAddresses(
                origins: origins,
                destinations: destinations,
                into: decodedOrderLabels
            )
        } else {
            orderLabels = decodedOrderLabels
        }

        self.init(
            currentOrderLabels: orderLabels,
            storedData: storedData
        )
    }

    private enum CodingKeys: String, CodingKey {
        case currentOrderLabels
        case storedData
    }
}

public extension WooShippingLabelData {
    typealias WooShippingLabelAddressMap = [String: WooShippingAddress]
    typealias WooShippingLabelAddressArray = [WooShippingAddress]

    struct StoredData: Decodable, Equatable {
        let selectedDestinations: WooShippingLabelAddressMap?
        let selectedOrigins: WooShippingLabelAddressMap?

        public enum CodingKeys: String, CodingKey {
            case selectedDestination = "selected_destination"
            case selectedOrigin = "selected_origin"
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            selectedDestinations = Self.decodeAddresses(
                from: container,
                for: .selectedDestination
            )

            selectedOrigins = Self.decodeAddresses(
                from: container,
                for: .selectedOrigin
            )
        }

        private static func decodeAddresses(
            from container: KeyedDecodingContainer<CodingKeys>,
            for key: CodingKeys
        ) -> WooShippingLabelAddressMap? {
            if let addressesMap = try? container.decodeIfPresent(
                WooShippingLabelAddressMap.self,
                forKey: key
            ) {
                return addressesMap
            } else if let addressesArray = try? container.decodeIfPresent(
                WooShippingLabelAddressArray.self,
                forKey: key
            ) {
                return addressesArray.enumerated().reduce(into: [:]) { result, address in
                    let formattedIDKey = WooShippingLabelData.formattedShipmentIDFromArrayIndex(address.offset)
                    result[formattedIDKey] = address.element
                }
            }

            return nil
        }
    }
}

// MARK: - Decoding Errors
//
enum WooShippingConfigDecodingError: Error {
    case missingSiteID
}
