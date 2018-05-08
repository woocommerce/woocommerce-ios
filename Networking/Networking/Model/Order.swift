import Foundation


///
///
public struct Order {
    public let identifier: Int
    public let parentIdentifier: Int
    public let customerIdentifier: Int

    public let number: String
    public let status: String
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
}


///
///
extension Order: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderKeys.self)

        identifier = try container.decode(Int.self, forKey: .identifier)
        parentIdentifier = try container.decode(Int.self, forKey: .parentIdentifier)
        customerIdentifier = try container.decode(Int.self, forKey: .customerIdentifier)

        number = try container.decode(String.self, forKey: .number)
        status = try container.decode(String.self, forKey: .status)
        currency = try container.decode(String.self, forKey: .currency)
        customerNote = try container.decode(String.self, forKey: .customerNote)

        dateCreated = try container.decodeDateAsString(forKey: .dateCreated)
        dateModified = try container.decodeDateAsString(forKey: .dateModified)
        datePaid = try container.decodeDateAsStringIfExists(forKey: .datePaid)

        dateCreatedGMT = try container.decodeDateAsString(forKey: .dateCreatedGMT)
        dateModifiedGMT = try container.decodeDateAsString(forKey: .dateModifiedGMT)
        datePaidGMT = try container.decodeDateAsStringIfExists(forKey: .datePaidGMT)

        discountTotal = try container.decode(String.self, forKey: .discountTotal)
        discountTax = try container.decode(String.self, forKey: .discountTax)
        shippingTotal = try container.decode(String.self, forKey: .shippingTotal)
        shippingTax = try container.decode(String.self, forKey: .shippingTax)
        total = try container.decode(String.self, forKey: .total)
        totalTax = try container.decode(String.self, forKey: .dateCreatedGMT)
    }
}


///
///
private enum OrderKeys: String, CodingKey {
    case identifier = "id"
    case parentIdentifier = "parent_id"
    case customerIdentifier = "customer_id"

    case number = "number"
    case status = "status"
    case currency = "currency"
    case customerNote = "customer_note"

    case dateCreated = "date_created"
    case dateModified = "date_modified"
    case datePaid = "date_paid"

    case dateCreatedGMT = "date_created_gmt"
    case dateModifiedGMT = "date_modified_gmt"
    case datePaidGMT = "date_paid_gmt"

    case discountTotal = "discount_total"
    case discountTax = "discount_tax"

    case shippingTotal = "shipping_total"
    case shippingTax = "shipping_tax"

    case total = "total"
    case totalTax = "total_tax"

//    case customer = "customer"
//    case shippingAddress = "shipping"
//    case billingAddress = "billing"
//    case orderItems = "line_items"
//    case notes = "notes"
}
