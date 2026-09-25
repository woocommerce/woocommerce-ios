import Foundation

/// Cash-session values returned by WooCommerce Core. Money remains decimal text until the POS layer maps it.
public struct POSCashSessionResponse: Decodable {
    public let id: Int64
    public let deviceID: String
    public let status: String
    public let revision: Int
    public let currency: String
    public let currencyPrecision: Int
    public let openingAmount: String
    public let cashSalesTotal: String
    public let cashRefundsTotal: String
    public let paidInTotal: String
    public let paidOutTotal: String
    public let expectedAmount: String
    public let countedAmount: String?
    public let variance: String?
    public let note: String?
    public let dateCreatedGMT: String
    public let dateClosedGMT: String?
    public let openedByName: String
    public let closedByName: String?

    private enum CodingKeys: String, CodingKey {
        case id, status, revision, currency, variance, note
        case deviceID = "device_id"
        case currencyPrecision = "currency_precision"
        case openingAmount = "opening_amount"
        case cashSalesTotal = "cash_sales_total"
        case cashRefundsTotal = "cash_refunds_total"
        case paidInTotal = "paid_in_total"
        case paidOutTotal = "paid_out_total"
        case expectedAmount = "expected_amount"
        case countedAmount = "counted_amount"
        case dateCreatedGMT = "date_created_gmt"
        case dateClosedGMT = "date_closed_gmt"
        case openedByName = "opened_by_name"
        case closedByName = "closed_by_name"
    }
}

public struct POSCashMovementResponse: Decodable {
    public let id: Int64
    public let type: String
    public let amount: String
    public let reason: String?
    public let orderID: Int64?
    public let occurredAt: String
    public let createdByName: String

    private enum CodingKeys: String, CodingKey {
        case id, type, amount, reason
        case orderID = "order_id"
        case occurredAt = "occurred_at"
        case createdByName = "created_by_name"
    }
}
