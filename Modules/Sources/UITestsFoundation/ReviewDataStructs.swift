public struct ReviewMock: Codable {
    public let response: ReviewResponseData
}

public struct ReviewResponseData: Codable {
    public let status: Int
    public let jsonBody: ReviewBodyData
}

public struct ReviewBodyData: Codable {
    public let data: [ReviewData]
}

public struct ReviewData: Codable {
    public let id: Int
    public let review: String
    public let reviewer: String
    public var product_id: Int
    public var product_name: String?
}
