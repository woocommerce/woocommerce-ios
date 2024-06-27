import Foundation
import Codegen

/// Represents a single campaign stat for a specific period.
///
public struct GoogleAdsCampaignStatsItem: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// Campaign ID
    ///
    public let campaignID: Int64

    /// Campaign name
    ///
    public let campaignName: String?

    /// Campaign status (raw value)
    ///
    public let rawStatus: String

    /// Campaign status
    ///
    public var status: Status {
        Status(rawValue: rawStatus) ?? .removed
    }

    /// Subtotal stats
    ///
    public let subtotals: GoogleAdsCampaignStatsTotals


    /// Designated Initializer.
    ///
    public init(campaignID: Int64, campaignName: String?, rawStatus: String, subtotals: GoogleAdsCampaignStatsTotals) {
        self.campaignID = campaignID
        self.campaignName = campaignName ?? ""
        self.rawStatus = rawStatus
        self.subtotals = subtotals
    }
}

public extension GoogleAdsCampaignStatsItem {
    enum Status: String {
        case enabled
        case paused
        case removed
    }
}


// MARK: - Constants!
//
private extension GoogleAdsCampaignStatsItem {
    enum CodingKeys: String, CodingKey {
        case campaignID     = "id"
        case campaignName   = "name"
        case rawStatus      = "status"
        case subtotals
    }
}

// MARK: - Identifiable Conformance
//
extension GoogleAdsCampaignStatsItem: Identifiable {
    public var id: Int64 {
        campaignID
    }
}
