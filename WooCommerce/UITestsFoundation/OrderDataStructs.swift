public struct OrderMock: Codable {
    public let response: OrderResponseData
}

public struct OrderResponseData: Codable {
    public let status: Int
    public let jsonBody: OrderBodyData
}

public struct OrderBodyData: Codable {
    public let data: [OrderData]
}

public struct OrderData: Codable {
    public let id: Int
    public let number: String
    public let status: String
    public var total: String
    public let line_items: [LineItems]
    public let billing: BillingInformation
}

public struct LineItems: Codable {
    public let name: String
    public let product_id: Int
}

public struct BillingInformation: Codable {
    public let first_name: String
    public let last_name: String
}
