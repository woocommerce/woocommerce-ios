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
    public var status: String
    public let total: String
    public let product_id: String
}
