import Foundation
import Codegen

/// Represents an Order Fulfillment Entity (from the WooCommerce Order Fulfillments endpoint).
///
/// Fulfillments contain shipment details — tracking number, shipping provider, tracking URL, and fulfillment date —
/// stored as private metadata on the fulfillment entity.
///
public struct OrderFulfillment: Decodable, Sendable, Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Site Identifier.
    ///
    public let siteID: Int64

    /// Order Identifier.
    ///
    public let orderID: Int64

    /// Unique identifier for the fulfillment.
    ///
    public let fulfillmentID: Int64

    /// Fulfillment status (e.g. "fulfilled").
    ///
    public let status: String?

    /// Whether the fulfillment is marked as fulfilled.
    ///
    public let isFulfilled: Bool

    /// Date when the fulfillment was last updated.
    ///
    public let dateUpdated: Date?

    /// Date when the order was fulfilled (from `_date_fulfilled` meta).
    ///
    public let dateFulfilled: Date?

    /// Shipment tracking number (from `_tracking_number` meta).
    ///
    public let trackingNumber: String?

    /// Shipping provider slug (from `_shipment_provider` meta).
    ///
    public let shipmentProvider: String?

    /// Custom provider name (from `_provider_name` meta).
    /// When the user selects "other" as the shipping provider, they can specify a custom provider name.
    ///
    public let providerName: String?

    /// External tracking URL (from `_tracking_url` meta).
    ///
    public let trackingURL: String?

    /// OrderFulfillment struct initializer.
    ///
    public init(siteID: Int64,
                orderID: Int64,
                fulfillmentID: Int64,
                status: String?,
                isFulfilled: Bool,
                dateUpdated: Date?,
                dateFulfilled: Date?,
                trackingNumber: String?,
                shipmentProvider: String?,
                providerName: String?,
                trackingURL: String?) {
        self.siteID = siteID
        self.orderID = orderID
        self.fulfillmentID = fulfillmentID
        self.status = status
        self.isFulfilled = isFulfilled
        self.dateUpdated = dateUpdated
        self.dateFulfilled = dateFulfilled
        self.trackingNumber = trackingNumber
        self.shipmentProvider = shipmentProvider
        self.providerName = providerName
        self.trackingURL = trackingURL
    }

    /// The public initializer for OrderFulfillment.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw OrderFulfillmentDecodingError.missingSiteID
        }
        guard let orderID = decoder.userInfo[.orderID] as? Int64 else {
            throw OrderFulfillmentDecodingError.missingOrderID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let fulfillmentID = try container.decode(Int64.self, forKey: .id)

        let status = try container.decodeIfPresent(String.self, forKey: .status)
        let isFulfilled = try container.decodeIfPresent(Bool.self, forKey: .isFulfilled) ?? false
        let dateUpdated = try container.decodeIfPresent(Date.self, forKey: .dateUpdated)

        // Extract metadata fields using the shared MetaData type (same as Order)
        let metaData = [MetaData].decodeFlexibly(from: container, forKey: .metaData)

        let trackingNumber = metaData.first(where: { $0.key == MetaKeys.trackingNumber })?.value.stringValue
        let shipmentProvider = metaData.first(where: { $0.key == MetaKeys.shipmentProvider })?.value.stringValue
        let providerName = metaData.first(where: { $0.key == MetaKeys.providerName })?.value.stringValue
        let trackingURL = metaData.first(where: { $0.key == MetaKeys.trackingURL })?.value.stringValue
        let dateFulfilledString = metaData.first(where: { $0.key == MetaKeys.dateFulfilled })?.value.stringValue
        let dateFulfilled = dateFulfilledString.flatMap { DateFormatter.Stats.dateTimeFormatter.date(from: $0) }

        self.init(siteID: siteID,
                  orderID: orderID,
                  fulfillmentID: fulfillmentID,
                  status: status,
                  isFulfilled: isFulfilled,
                  dateUpdated: dateUpdated,
                  dateFulfilled: dateFulfilled,
                  trackingNumber: trackingNumber,
                  shipmentProvider: shipmentProvider,
                  providerName: providerName,
                  trackingURL: trackingURL)
    }
}


// MARK: - CodingKeys
//
private extension OrderFulfillment {

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case isFulfilled = "is_fulfilled"
        case dateUpdated = "date_updated"
        case metaData = "meta_data"
    }

    enum MetaKeys {
        static let dateFulfilled = "_date_fulfilled"
        static let trackingNumber = "_tracking_number"
        static let shipmentProvider = "_shipment_provider"
        static let providerName = "_provider_name"
        static let trackingURL = "_tracking_url"
    }
}


// MARK: - Decoding Errors
//
enum OrderFulfillmentDecodingError: Error {
    case missingSiteID
    case missingOrderID
}
