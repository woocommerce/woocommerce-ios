import Foundation


/// Mapper: v4 `POST refunds` response → existing `Refund` model.
///
/// The v4 response cannot be decoded with `Refund`'s v3 decoder: it merges products, fees and
/// shipping into a single `line_items` array with no type discriminator, and returns positive
/// magnitudes (v3 stores them negative). Every line is mapped into `items`
/// with negated values, and `shippingLines`/`feeLines` are left empty.
///
struct RefundV4Mapper: Mapper {

    /// Site Identifier associated to the refund that will be parsed.
    /// Injected because it is not returned by the endpoint.
    ///
    let siteID: Int64

    /// Order Identifier associated with the refund that will be parsed.
    /// Injected because the v4 path is not nested under the order.
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into a Refund.
    ///
    func map(response: Data) throws -> Refund {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        let refundV4: RefundV4Response
        if hasDataEnvelope(in: response) {
            refundV4 = try decoder.decode(RefundV4Envelope.self, from: response).refund
        } else {
            refundV4 = try decoder.decode(RefundV4Response.self, from: response)
        }
        return refund(from: refundV4)
    }
}

private extension RefundV4Mapper {
    func refund(from response: RefundV4Response) -> Refund {
        Refund(refundID: response.id,
               orderID: orderID,
               siteID: siteID,
               dateCreated: response.dateCreated,
               amount: response.amount,
               reason: response.reason,
               refundedByUserID: 0,
               isAutomated: response.refundedPayment,
               createAutomated: nil,
               items: response.lineItems.map(item(from:)),
               shippingLines: [],
               feeLines: [])
    }

    /// Maps one merged v4 line into an `OrderItemRefund`, negating the magnitudes per the v3 storage contract.
    func item(from line: RefundV4Response.LineItem) -> OrderItemRefund {
        let subtotal = Decimal(string: line.refundTotal) ?? .zero
        let totalTax = line.refundTax.reduce(Decimal.zero) { sum, tax in
            sum + (Decimal(string: tax.refundTotal) ?? .zero)
        }
        let total = subtotal + totalTax

        return OrderItemRefund(itemID: line.id,
                               refundedItemID: String(line.lineItemID),
                               quantity: -line.quantity,
                               subtotal: (-subtotal).description,
                               taxes: line.refundTax.map { tax in
                                   let taxTotal = Decimal(string: tax.refundTotal) ?? .zero
                                   return OrderItemTaxRefund(taxID: tax.id,
                                                             subtotal: "",
                                                             total: (-taxTotal).description)
                               },
                               total: (-total).description,
                               totalTax: (-totalTax).description)
    }
}


/// v4 create response. Line items merge products/fees/shipping with no type marker.
///
/// WooCommerce core's v4 refund schema does not mark these response fields as nullable, and the
/// response builder emits them from concrete refund values. The fields are required here so mapping
/// fails loudly if the API contract changes or returns a malformed create response.
private struct RefundV4Response: Decodable {
    let id: Int64
    let dateCreated: Date
    let amount: String
    let reason: String
    let refundedPayment: Bool
    let lineItems: [LineItem]

    struct LineItem: Decodable {
        let id: Int64
        let lineItemID: Int64
        let quantity: Decimal
        let refundTotal: String
        let refundTax: [LineItemTax]

        enum CodingKeys: String, CodingKey {
            case id
            case lineItemID = "line_item_id"
            case quantity
            case refundTotal = "refund_total"
            case refundTax = "refund_tax"
        }
    }

    struct LineItemTax: Decodable {
        let id: Int64
        let refundTotal: String

        enum CodingKeys: String, CodingKey {
            case id
            case refundTotal = "refund_total"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case dateCreated = "date_created"
        case amount
        case reason
        case refundedPayment = "refunded_payment"
        case lineItems = "line_items"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        amount = try container.decode(String.self, forKey: .amount)
        reason = try container.decode(String.self, forKey: .reason)
        refundedPayment = try container.decode(Bool.self, forKey: .refundedPayment)
        lineItems = try container.decode([LineItem].self, forKey: .lineItems)
    }
}


/// RefundV4Envelope Disposable Entity
///
private struct RefundV4Envelope: Decodable {
    let refund: RefundV4Response

    private enum CodingKeys: String, CodingKey {
        case refund = "data"
    }
}
