#if os(iOS)

import Foundation
import Codegen

/// Represents an Order Item that was refunded or will be refunded.
///
public struct OrderItemRefund: Codable, Equatable, GeneratedFakeable, GeneratedCopiable, Hashable {
    public let itemID: Int64
    public let name: String
    public let productID: Int64
    public let variationID: Int64
    public let refundedItemID: String?
    public let quantity: Decimal

    /// Price is a currency.
    /// When handling currencies, `NSDecimalNumber` is a powerhouse
    /// for localization and string-to-number conversions.
    /// `Decimal` doesn't yet have all of the `NSDecimalNumber` APIs.
    ///
    public let price: NSDecimalNumber
    public let sku: String?
    public let subtotal: String
    public let subtotalTax: String
    public let taxClass: String
    public let taxes: [OrderItemTaxRefund]
    public let total: String
    public let totalTax: String

    /// OrderItemRefund struct initializer.
    ///
    public init(itemID: Int64,
                name: String,
                productID: Int64,
                variationID: Int64,
                refundedItemID: String?,
                quantity: Decimal,
                price: NSDecimalNumber,
                sku: String?,
                subtotal: String,
                subtotalTax: String,
                taxClass: String,
                taxes: [OrderItemTaxRefund],
                total: String,
                totalTax: String) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.variationID = variationID
        self.refundedItemID = refundedItemID
        self.quantity = quantity
        self.price = price
        self.sku = sku
        self.subtotal = subtotal
        self.subtotalTax = subtotalTax
        self.taxClass = taxClass
        self.taxes = taxes
        self.total = total
        self.totalTax = totalTax
    }

    /// The public decoder for OrderItemRefund.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DecodingKeys.self)

        let itemID = try container.decode(Int64.self, forKey: .itemID)
        let name = try container.decode(String.self, forKey: .name)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let variationID = try container.decode(Int64.self, forKey: .variationID)

        let quantity = try container.decode(Decimal.self, forKey: .quantity)
        let decimalPrice = try container.decodeIfPresent(Decimal.self, forKey: .price) ?? Decimal(0)
        let price = NSDecimalNumber(decimal: decimalPrice)

        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let subtotalTax = try container.decode(String.self, forKey: .subtotalTax)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let taxes = try container.decode([OrderItemTaxRefund].self, forKey: .taxes)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)

        let allOrderItemRefundMetaData = try container.decode([OrderItemRefundMetaData].self, forKey: .metadata)
        let refundedItemID = allOrderItemRefundMetaData.first(where: { $0.key == "_refunded_item_id" })?.value

        // initialize the struct
        self.init(itemID: itemID,
                  name: name,
                  productID: productID,
                  variationID: variationID,
                  refundedItemID: refundedItemID,
                  quantity: quantity,
                  price: price,
                  sku: sku,
                  subtotal: subtotal,
                  subtotalTax: subtotalTax,
                  taxClass: taxClass,
                  taxes: taxes,
                  total: total,
                  totalTax: totalTax)
    }

    /// The public encoder for OrderItemRefund.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)

        try container.encode(quantity, forKey: .quantity)
        try container.encode(total, forKey: .total)
        try container.encode(taxesDictionary(), forKey: .taxes)
    }

    /// Converts the taxes array to a dictionary as the API expects it.
    /// {  "tax_id_1" : "1.99", "tax_id_2" : "0.99" }
    ///
    private func taxesDictionary() -> [String: String] {
        taxes.reduce(into: [:]) { dictionary, taxItem in
            dictionary[String(taxItem.taxID)] = taxItem.total
        }
    }
}


/// Defines all of the OrderItemRefund CodingKeys.
///
private extension OrderItemRefund {

    enum DecodingKeys: String, CodingKey {
        case itemID         = "id"
        case variationID    = "variation_id"
        case name
        case productID      = "product_id"
        case quantity
        case price
        case sku
        case subtotal
        case subtotalTax    = "subtotal_tax"
        case taxClass       = "tax_class"
        case total
        case totalTax       = "total_tax"
        case taxes
        case metadata       = "meta_data"
    }

    enum EncodingKeys: String, CodingKey {
        case quantity = "qty"
        case total = "refund_total"
        case taxes = "refund_tax"
    }
}

#endif
