/// POS order history can show a partial page when a single order payload is malformed.
/// The regular `OrderListMapper` stays strict for the rest of the app.
struct LossyPOSOrder: Decodable {
    let order: Order?

    init(from decoder: Decoder) throws {
        do {
            order = try Order(from: decoder)
        } catch {
            order = nil
            let siteID = decoder.userInfo[.siteID] as? Int64
            let descriptor = (try? SkippedOrderDescriptor(from: decoder))?.description ?? "unknown order"
            DDLogError("POSOrderListMapper: Skipping malformed POS order for siteID \(siteID ?? 0), \(descriptor): \(error)")
        }
    }
}

private struct SkippedOrderDescriptor: Decodable {
    let orderID: Int64?
    let number: String?

    var description: String {
        switch (orderID, number) {
        case let (orderID?, number?):
            return "orderID \(orderID), number \(number)"
        case let (orderID?, nil):
            return "orderID \(orderID)"
        case let (nil, number?):
            return "number \(number)"
        case (nil, nil):
            return "unknown order"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderID = try container.decodeIfPresent(Int64.self, forKey: .orderID)
        number = try container.decodeIfPresent(String.self, forKey: .number)
    }

    private enum CodingKeys: String, CodingKey {
        case orderID = "id"
        case number
    }
}
