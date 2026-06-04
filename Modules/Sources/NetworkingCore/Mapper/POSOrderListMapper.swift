import Foundation

/// Mapper: POS OrderList
///
/// POS order history can show a partial page when a single order payload is malformed.
/// The regular `OrderListMapper` stays strict for the rest of the app.
struct POSOrderListMapper: Mapper {
    /// Site Identifier associated to the orders that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64

    /// Attempts to convert a dictionary into `[Order]`, skipping individual malformed orders.
    ///
    func map(response: Data) throws -> [Order] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(POSOrderListEnvelope.self, from: response).orders
        } else {
            return try decoder.decode(LossyPOSOrderList.self, from: response).orders
        }
    }
}

private struct POSOrderListEnvelope: Decodable {
    let orders: [Order]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orders = try container.decode(LossyPOSOrderList.self, forKey: .orders).orders
    }

    private enum CodingKeys: String, CodingKey {
        case orders = "data"
    }
}

private struct LossyPOSOrderList: Decodable {
    let orders: [Order]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let wrappers = try container.decode([LossyPOSOrder].self)
        orders = wrappers.compactMap(\.order)
    }
}

private struct LossyPOSOrder: Decodable {
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
