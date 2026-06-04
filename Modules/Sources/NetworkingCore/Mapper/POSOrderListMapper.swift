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

        return try decoder.decode(POSOrderListResponse.self, from: response).orders
    }
}

private struct POSOrderListResponse: Decodable {
    let orders: [Order]

    init(from decoder: Decoder) throws {
        if let keyedContainer = try? decoder.container(keyedBy: CodingKeys.self),
           keyedContainer.contains(.data) {
            orders = try keyedContainer.decode([LossyPOSOrder].self, forKey: .data).compactMap(\.order)
            return
        }

        let container = try decoder.singleValueContainer()
        orders = try container.decode([LossyPOSOrder].self).compactMap(\.order)
    }

    private enum CodingKeys: String, CodingKey {
        case data
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
