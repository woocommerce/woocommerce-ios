import Codegen
import Foundation

/// Details for a Google ads campaign.
///
public struct GoogleAdsCampaign: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

    public let id: Int64

    public let name: String

    public let rawStatus: String

    public let rawType: String

    public let amount: Double

    public let country: String

    public let targetedLocations: [String]

    public var status: Status {
        Status(rawValue: rawStatus) ?? .disabled
    }

    public init(id: Int64,
                name: String,
                rawStatus: String,
                rawType: String,
                amount: Double,
                country: String,
                targetedLocations: [String]) {
        self.id = id
        self.name = name
        self.rawStatus = rawStatus
        self.rawType = rawType
        self.amount = amount
        self.country = country
        self.targetedLocations = targetedLocations
    }
}

public extension GoogleAdsCampaign {
    enum Status: String {
        case enabled
        case disabled
        case removed
    }
}

private extension GoogleAdsCampaign {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rawStatus = "status"
        case rawType = "type"
        case amount
        case country
        case targetedLocations = "targeted_locations"
    }
}
