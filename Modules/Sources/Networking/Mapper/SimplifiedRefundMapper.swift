import Foundation


/// Mapper: v4 `POST refunds` (simplified create) response → existing `Refund` model.
///
/// The v4 response cannot be decoded with `Refund`'s v3 decoder: it merges products, fees and
/// shipping into a single `line_items` array with no type discriminator, and returns positive
/// magnitudes (v3 stores them negative). Every line is mapped into `items`
/// with negated values, and `shippingLines`/`feeLines` are left empty.
///
struct SimplifiedRefundMapper: Mapper {

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

        let simplified: SimplifiedRefundResponse
        if hasDataEnvelope(in: response) {
            simplified = try decoder.decode(SimplifiedRefundEnvelope.self, from: response).refund
        } else {
            simplified = try decoder.decode(SimplifiedRefundResponse.self, from: response)
        }
        return refund(from: simplified)
    }
}

private extension SimplifiedRefundMapper {
    func refund(from response: SimplifiedRefundResponse) -> Refund {
        Refund(refundID: response.id,
               orderID: orderID,
               siteID: siteID,
               dateCreated: response.dateCreated ?? Date(),
               amount: response.amount ?? "0",
               reason: response.reason ?? "",
               refundedByUserID: 0,
               isAutomated: response.refundedPayment,
               createAutomated: nil,
               items: (response.lineItems ?? []).map(item(from:)),
               shippingLines: [],
               feeLines: [])
    }

    /// Maps one merged v4 line into an `OrderItemRefund`, negating the magnitudes per the v3 storage contract.
    func item(from line: SimplifiedRefundResponse.LineItem) -> OrderItemRefund {
        let subtotal = line.refundTotal.flatMap { Decimal(string: $0) } ?? .zero
        let totalTax = (line.refundTax ?? []).reduce(Decimal.zero) { sum, tax in
            sum + (tax.refundTotal.flatMap { Decimal(string: $0) } ?? .zero)
        }
        let total = subtotal + totalTax
        let quantity = line.quantity ?? .zero

        return OrderItemRefund(itemID: line.id ?? 0,
                               refundedItemID: line.lineItemID.map(String.init),
                               quantity: -quantity,
                               subtotal: (-subtotal).description,
                               taxes: (line.refundTax ?? []).map { tax in
                                   let taxTotal = tax.refundTotal.flatMap { Decimal(string: $0) } ?? .zero
                                   return OrderItemTaxRefund(taxID: tax.id ?? 0,
                                                             subtotal: "",
                                                             total: (-taxTotal).description)
                               },
                               total: (-total).description,
                               totalTax: (-totalTax).description)
    }
}


/// v4 simplified create response. Line items merge products/fees/shipping with no type marker.
///
private struct SimplifiedRefundResponse: Decodable {
    let id: Int64
    let dateCreated: Date?
    let amount: String?
    let reason: String?
    let refundedPayment: Bool?
    let lineItems: [LineItem]?

    struct LineItem: Decodable {
        let id: Int64?
        let lineItemID: Int64?
        let quantity: Decimal?
        let refundTotal: String?
        let refundTax: [LineItemTax]?

        enum CodingKeys: String, CodingKey {
            case id
            case lineItemID = "line_item_id"
            case quantity
            case refundTotal = "refund_total"
            case refundTax = "refund_tax"
        }
    }

    struct LineItemTax: Decodable {
        let id: Int64?
        let refundTotal: String?

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
        dateCreated = try? container.decodeIfPresent(Date.self, forKey: .dateCreated)
        amount = try? container.decodeIfPresent(String.self, forKey: .amount)
        reason = try? container.decodeIfPresent(String.self, forKey: .reason)
        refundedPayment = try? container.decodeIfPresent(Bool.self, forKey: .refundedPayment)
        lineItems = try? container.decodeIfPresent([LineItem].self, forKey: .lineItems)
    }
}


/// SimplifiedRefundEnvelope Disposable Entity
///
private struct SimplifiedRefundEnvelope: Decodable {
    let refund: SimplifiedRefundResponse

    private enum CodingKeys: String, CodingKey {
        case refund = "data"
    }
}
