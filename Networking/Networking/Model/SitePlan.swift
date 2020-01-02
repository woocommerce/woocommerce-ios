import Foundation


/// Represents a WordPress.com default Site's plan.
///
public struct SitePlan: Decodable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int64

    /// Short name for the site's plan.
    ///
    public let shortName: String


    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        let sitePlanContainer = try decoder.container(keyedBy: PlanKeys.self)
        let siteID = try sitePlanContainer.decode(Int64.self, forKey: .siteID)

        let planContainer = try sitePlanContainer.nestedContainer(keyedBy: PlanKeys.self, forKey: .plan)
        let shortName = try planContainer.decode(String.self, forKey: .shortName)

        self.init(siteID: siteID,
                  shortName: shortName)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int64, shortName: String) {
        self.siteID = siteID
        self.shortName = shortName
    }
}


// MARK: - Comparable Conformance
//
extension SitePlan: Comparable {
    public static func < (lhs: SitePlan, rhs: SitePlan) -> Bool {
        return lhs.siteID < rhs.siteID
    }

    public static func == (lhs: SitePlan, rhs: SitePlan) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.shortName == rhs.shortName
    }
}


/// Defines all of the SitePlan CodingKeys.
///
private extension SitePlan {

    enum PlanKeys: String, CodingKey {
        case siteID         = "ID"
        case plan           = "plan"
        case shortName      = "product_name_short"
    }
}
