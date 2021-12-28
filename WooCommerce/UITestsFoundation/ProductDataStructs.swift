public struct MockFile: Codable {
    public let response: ResponseData
}

public struct ResponseData: Codable {
    public let status: Int
    public let jsonBody: BodyData
}

public struct BodyData: Codable {
    public let data: [ProductData]
}

public struct ProductData: Codable {
    public let id: Int
    public let name: String
    public var stock_status: String
    public let regular_price: String
}
