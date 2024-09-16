import Codegen
import Foundation

/// Connection details for Google Listings & Ads extension.
///
public struct GoogleAdsConnection: Equatable, Decodable, GeneratedFakeable, GeneratedCopiable {

    public let id: Int64

    public let currency: String

    public let symbol: String

    public let rawStatus: String

    public var status: Status {
        Status(rawValue: rawStatus) ?? .disconnected
    }

    public init(id: Int64, currency: String, symbol: String, rawStatus: String) {
        self.id = id
        self.currency = currency
        self.symbol = symbol
        self.rawStatus = rawStatus
    }
}

public extension GoogleAdsConnection {
    enum Status: String {
        case disconnected
        case incomplete
        case connected
    }
}

private extension GoogleAdsConnection {
    enum CodingKeys: String, CodingKey {
        case id
        case currency
        case symbol
        case rawStatus = "status"
    }
}
