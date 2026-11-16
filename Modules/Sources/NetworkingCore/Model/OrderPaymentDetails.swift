import Foundation

/// Payment metadata is fetched separately because Order excludes internal metadata from its custom fields.
public struct OrderPaymentDetails: Decodable, Sendable {
    public let orderID: Int64
    public let isPaid: Bool
    public let wooPaymentsIntentID: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderID = try container.decode(Int64.self, forKey: .orderID)
        isPaid = try container.decode(String?.self, forKey: .datePaid)?.isEmpty == false
        let metadata = try container.decode([MetaData].self, forKey: .metadata)
        wooPaymentsIntentID = metadata.first(where: { $0.key == "_intent_id" })?.value.stringValue
    }

    private enum CodingKeys: String, CodingKey {
        case orderID = "id"
        case datePaid = "date_paid"
        case metadata = "meta_data"
    }
}
