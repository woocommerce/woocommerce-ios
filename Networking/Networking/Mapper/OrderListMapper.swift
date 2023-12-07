import Foundation


/// Mapper: OrderList
///
struct OrderListMapper: Mapper {

    /// Site Identifier associated to the orders that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into [Order].
    ///
    func map(response: Data) throws -> [Order] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(OrderListEnvelope.self, from: response).orders
        } else {
            return try decoder.decode([Order].self, from: response)
        }
    }
}


/// OrderList Disposable Entity:
/// `Load All Orders` endpoint returns all of its orders within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderListEnvelope: Decodable {
    let orders: [Order]

    private enum CodingKeys: String, CodingKey {
        case orders = "data"
    }
}


public struct FaultyOrder: Decodable {
    public let id: Int64
    public let number: String
    public let date: Date?
    public let currency: String
    public let total: String
    public let status: OrderStatusEnum
    public let billingAddress: Address?

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case date = "date_created_gmt"
        case currency = "currency_symbol"
        case total
        case status
        case billingAddress = "billing"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.number = (try? container.decode(String.self, forKey: .number)) ?? "-"
        self.date = try? container.decode(Date.self, forKey: .date)
        self.currency = (try? container.decode(String.self, forKey: .currency)) ?? ""
        self.total = (try? container.decode(String.self, forKey: .total)) ?? ""
        self.status = (try? container.decode(OrderStatusEnum.self, forKey: .status)) ?? .custom("Unknown")
        self.billingAddress = try? container.decode(Address.self, forKey: .billingAddress)
    }
}

public struct Faulty<Element: Decodable> {
    public let element: Element
    public let error: DecodingError

}

public extension DecodingError {
    var context: Context {
        switch self {
        case .dataCorrupted(let context), .keyNotFound(_, let context), .typeMismatch(_, let context), .valueNotFound(_, let context):
            return context
        @unknown default:
            assertionFailure("⛔️ Unhandled Decoding Error: \(self)")
            return Context(codingPath: [], debugDescription: "")
        }
    }

    var debugPath: String {
        context.codingPath.map { $0.stringValue }.joined(separator: ".")
    }

    var debugDescription: String {
        context.debugDescription
    }
}

public struct ListResponse<Element: Decodable, FailedElement: Decodable>: Decodable {
    public private(set) var elements: [Element] = []
    public private(set) var fails: [Faulty<FailedElement>] = []

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        while !container.isAtEnd {
            do {
                let element = try container.decode(Element.self)
                elements.append(element)
            }
            catch let error as DecodingError {

                let failed = try container.decode(FailedElement.self)
                let faulty = Faulty(element: failed, error: error)
                fails.append(faulty)

                DDLogError("⛔️ Error decoding \(Element.self) at \"\(error.debugPath)\"\n\(error.debugDescription)")
            }
        }
    }
}

private struct OrderListTestEnvelope: Decodable {
    let response: ListResponse<Order, FaultyOrder>

    private enum CodingKeys: String, CodingKey {
        case response = "data"
    }
}


/// Mapper: OrderList
///
struct OrderListTestMapper: Mapper {

    /// Site Identifier associated to the orders that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into [Order].
    ///
    func map(response: Data) throws -> ListResponse<Order, FaultyOrder> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(OrderListTestEnvelope.self, from: response).response
        } else {
            return try decoder.decode(ListResponse<Order, FaultyOrder>.self, from: response)
        }
    }
}
