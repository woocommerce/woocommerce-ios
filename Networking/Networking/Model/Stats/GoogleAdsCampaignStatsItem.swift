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

    /// Campaign status
    ///
    public let status: String

    /// Subtotal stats
    ///
    public let subtotals: GoogleAdsCampaignStatsTotals


    /// Designated Initializer.
    ///
    public init(campaignID: Int64, campaignName: String?, status: String, subtotals: GoogleAdsCampaignStatsTotals) {
        self.campaignID = campaignID
        self.campaignName = campaignName ?? ""
        self.status = status
        self.subtotals = subtotals
    }
}


// MARK: - Constants!
//
private extension GoogleAdsCampaignStatsItem {
    enum CodingKeys: String, CodingKey {
        case campaignID     = "id"
        case campaignName   = "name"
        case status
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
