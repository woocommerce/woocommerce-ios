import Foundation


/// Represents a WordPress.com default Site's plan.
///
public struct SitePlan: Decodable {

    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int

    /// Short name for the site's plan.
    ///
    public var shortName: String?


    /// Decodable Conformance.
    ///
    public init(from decoder: Decoder) throws {
        let sitePlanContainer = try decoder.container(keyedBy: PlanKeys.self)
        let siteID = try sitePlanContainer.decode(Int.self, forKey: .siteID)

        var shortName: String?
        if sitePlanContainer.contains(.plan) {
            let planContainer = try sitePlanContainer.nestedContainer(keyedBy: PlanKeys.self, forKey: .plan)
            shortName = try planContainer.decodeIfPresent(String.self, forKey: .shortName)
        }

        self.init(siteID: siteID,
                  shortName: shortName)
    }

    /// Designated Initializer.
    ///
    public init(siteID: Int, shortName: String?) {
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
