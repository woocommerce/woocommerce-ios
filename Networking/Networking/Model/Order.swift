import Foundation


/// Represents an Order Entity.
///
public struct Order: Decodable {
    public let identifier: Int
    public let parentIdentifier: Int
    public let customerIdentifier: Int

    public let number: String
    public let status: OrderStatus
    public let currency: String
    public let customerNote: String?

    public let dateCreated: Date
    public let dateModified: Date
    public let datePaid: Date?

    public let dateCreatedGMT: Date
    public let dateModifiedGMT: Date
    public let datePaidGMT: Date?

    public let discountTotal: String
    public let discountTax: String
    public let shippingTotal: String
    public let shippingTax: String
    public let total: String
    public let totalTax: String

    public let billingAddress: Address
    public let shippingAddress: Address
}


// TODO: Add missing properties


/// Defines all of the Order CodingKeys
///
private extension Order {

    enum CodingKeys: String, CodingKey {
        case identifier         = "id"
        case parentIdentifier   = "parent_id"
        case customerIdentifier = "customer_id"

        case number             = "number"
        case status             = "status"
        case currency           = "currency"
        case customerNote       = "customer_note"

        case dateCreated        = "date_created"
        case dateModified       = "date_modified"
        case datePaid           = "date_paid"

        case dateCreatedGMT     = "date_created_gmt"
        case dateModifiedGMT    = "date_modified_gmt"
        case datePaidGMT        = "date_paid_gmt"

        case discountTotal      = "discount_total"
        case discountTax        = "discount_tax"
        case shippingTotal      = "shipping_total"
        case shippingTax        = "shipping_tax"
        case total              = "total"
        case totalTax           = "total_tax"

        case shippingAddress    = "shipping"
        case billingAddress     = "billing"
    }
}
