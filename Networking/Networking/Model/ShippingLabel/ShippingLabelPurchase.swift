import Foundation
import Codegen

/// Represents a Shipping Label purchase.
///
/// Shipping label purchases contain a subset of the label data included in a purchased `ShippingLabel`.
///
public struct ShippingLabelPurchase: Equatable, GeneratedCopiable, GeneratedFakeable {
    /// The remote ID of the site that owns this shipping label.
    public let siteID: Int64

    /// The remote ID of the order that owns the shipping label.
    public let orderID: Int64

    /// The remote ID of the shipping label.
    public let shippingLabelID: Int64

    /// The remote ID of the shipping carrier.
    public let carrierID: String?

    /// The date the shipping label was created.
    public let dateCreated: Date

    /// The name of the package for the shipping label.
    public let packageName: String

    /// The tracking number of the shipping label.
    public let trackingNumber: String?

    /// The name of service for the shipping label (e.g. "USPS - Media Mail").
    public let serviceName: String

    /// The amount that is refundable.
    public let refundableAmount: Double

    /// The status of the shipping label (e.g. `PURCHASE_IN_PROGRESS`).
    public let status: ShippingLabelStatus

    /// A list of product IDs included in the shipping label.
    /// This could be empty for older plugin versions.
    public let productIDs: [Int64]

    /// A list of product names included in the shipping label.
    /// This is only used to look up a product in case `productIDs` is not available.
    public let productNames: [String]

    public init(siteID: Int64,
                orderID: Int64,
                shippingLabelID: Int64,
                carrierID: String?,
                dateCreated: Date,
                packageName: String,
                trackingNumber: String?,
                serviceName: String,
                refundableAmount: Double,
                status: ShippingLabelStatus,
                productIDs: [Int64],
                productNames: [String]) {
        self.siteID = siteID
        self.orderID = orderID
        self.shippingLabelID = shippingLabelID
        self.carrierID = carrierID
        self.dateCreated = dateCreated
        self.packageName = packageName
        self.trackingNumber = trackingNumber
        self.serviceName = serviceName
        self.refundableAmount = refundableAmount
        self.status = status
        self.productIDs = productIDs
        self.productNames = productNames
    }
}

// MARK: Decodable
//
extension ShippingLabelPurchase: Decodable {
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ShippingLabelDecodingError.missingSiteID
        }

        guard let orderID = decoder.userInfo[.orderID] as? Int64 else {
            throw ShippingLabelDecodingError.missingOrderID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let shippingLabelID = try container.decode(Int64.self, forKey: .shippingLabelID)
        let carrierID = try container.decodeIfPresent(String.self, forKey: .carrierID)
        let dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        let packageName = try container.decode(String.self, forKey: .packageName)
        let trackingNumber = try container.decodeIfPresent(String.self, forKey: .trackingNumber)
        let serviceName = try container.decode(String.self, forKey: .serviceName)
        let refundableAmount = try container.decode(Double.self, forKey: .refundableAmount)

        let statusRawValue = try container.decode(String.self, forKey: .status)
        let status = ShippingLabelStatus(rawValue: statusRawValue)

        let productIDs = try container.decodeIfPresent([Int64].self, forKey: .productIDs) ?? []
        let productNames = try container.decode([String].self, forKey: .productNames)

        self.init(siteID: siteID,
                  orderID: orderID,
                  shippingLabelID: shippingLabelID,
                  carrierID: carrierID,
                  dateCreated: dateCreated,
                  packageName: packageName,
                  trackingNumber: trackingNumber,
                  serviceName: serviceName,
                  refundableAmount: refundableAmount,
                  status: status,
                  productIDs: productIDs,
                  productNames: productNames)
    }

    private enum CodingKeys: String, CodingKey {
        case siteID
        case orderID
        case shippingLabelID = "label_id"
        case carrierID = "carrier_id"
        case dateCreated = "created"
        case packageName = "package_name"
        case trackingNumber = "tracking"
        case serviceName = "service_name"
        case refundableAmount = "refundable_amount"
        case status
        case productIDs = "product_ids"
        case productNames = "product_names"
    }
}

// MARK: - Decoding Errors
//
enum ShippingLabelPurchaseDecodingError: Error {
    case missingSiteID
    case missingOrderID
}
