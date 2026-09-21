import Foundation
import Codegen

/// Represents a FeeLine Entity within an Order.
///
public struct OrderFeeLine: Equatable, Codable, Sendable, GeneratedFakeable, GeneratedCopiable {
    public let feeID: Int64

    /// Fee Name
    ///
    /// Sending a null value to the REST API removes the Fee Line from the Order.
    ///
    public let name: String?

    public let taxClass: String
    public let taxStatus: OrderFeeTaxStatus
    public let total: String
    public let totalTax: String
    public let taxes: [OrderItemTax]
    public let attributes: [OrderItemAttribute]

    /// When this fee line is part of a refund response, points back to the original order's
    /// fee line id (extracted from `_refunded_item_id` in `meta_data`). `nil` for fees on orders.
    public let refundedItemID: Int64?

    /// OrderFeeLine struct initializer.
    ///
    public init(feeID: Int64,
                name: String?,
                taxClass: String,
                taxStatus: OrderFeeTaxStatus,
                total: String,
                totalTax: String,
                taxes: [OrderItemTax],
                attributes: [OrderItemAttribute],
                refundedItemID: Int64? = nil) {
        self.feeID = feeID
        self.name = name
        self.taxClass = taxClass
        self.taxStatus = taxStatus
        self.total = total
        self.totalTax = totalTax
        self.taxes = taxes
        self.attributes = attributes
        self.refundedItemID = refundedItemID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let feeID = try container.decode(Int64.self, forKey: .feeID)
        let name = try container.decode(String.self, forKey: .name)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let taxStatus = try container.decode(OrderFeeTaxStatus.self, forKey: .taxStatus)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let taxes = try container.decode([OrderItemTax].self, forKey: .taxes)

        // Use failsafe decoding to discard any attributes with non-string values (currently not supported).
        let attributes = container.failsafeDecodeIfPresent(lossyList: [OrderItemAttribute].self, forKey: .attributes)

        // When this fee line belongs to a refund response, WC stores the original fee line id
        // in `meta_data` under the `_refunded_item_id` key. Decode it lossily so the field stays
        // `nil` for fees on orders (where the meta entry is absent). Uses a separate keyed
        // container so the JSON `meta_data` field is read as raw `[MetaData]` (preserving
        // underscored keys) rather than as the filtered `[OrderItemAttribute]` decoded above.
        let refundedItemID: Int64? = {
            let metaContainer = try? decoder.container(keyedBy: MetaDataKeys.self)
            guard let metaData = try? metaContainer?.decode([MetaData].self, forKey: .metaData),
                  let raw = metaData.first(where: { $0.key == "_refunded_item_id" })?.value.stringValue else {
                return nil
            }
            return Int64(raw)
        }()

        self.init(feeID: feeID,
                  name: name,
                  taxClass: taxClass,
                  taxStatus: taxStatus,
                  total: total,
                  totalTax: totalTax,
                  taxes: taxes,
                  attributes: attributes,
                  refundedItemID: refundedItemID)
    }
}

// MARK: Codable
extension OrderFeeLine {
    /// Encodes OrderFeeLine writable fields.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(feeID, forKey: .feeID)
        try container.encode(name, forKey: .name)
        try container.encode(taxClass, forKey: .taxClass)
        try container.encode(taxStatus, forKey: .taxStatus)
        try container.encode(total, forKey: .total)
    }
}

/// Defines all of the OrderFeeLine's CodingKeys.
///
private extension OrderFeeLine {

    enum CodingKeys: String, CodingKey {
        case feeID      = "id"
        case name       = "name"
        case taxClass   = "tax_class"
        case taxStatus  = "tax_status"
        case total      = "total"
        case totalTax   = "total_tax"
        case taxes      = "taxes"
        case attributes = "meta_data"
    }

    /// Used to decode `meta_data` as raw `[MetaData]` (preserving underscored keys like
    /// `_refunded_item_id`) instead of as `[OrderItemAttribute]` via the main `CodingKeys`.
    enum MetaDataKeys: String, CodingKey {
        case metaData = "meta_data"
    }
}
