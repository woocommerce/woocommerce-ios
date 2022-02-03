public struct ProductMock: Codable {
    public let response: ProductResponseData
}

public struct ProductResponseData: Codable {
    public let status: Int
    public let jsonBody: ProductBodyData
}

public struct ProductBodyData: Codable {
    public let data: [ProductData]
}

public struct ProductData: Codable {
    public let id: Int
    public let name: String
    public var stock_status: String
    public let regular_price: String
}
