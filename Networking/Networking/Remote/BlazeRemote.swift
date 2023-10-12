import Foundation

/// Protocol for `BlazeRemote` mainly used for mocking.
///
public protocol BlazeRemoteProtocol {
    /// Loads campaigns for the site with the provided ID on the given page number.
    /// - Parameters:
    ///    - siteID: WPCom ID for the site to load ads campaigns.
    ///    - pageNumber: the page number of campaign to load.
    ///
    func loadCampaigns(for siteID: Int64, pageNumber: Int) async throws -> [BlazeCampaign]
}

/// Blaze: Remote Endpoints
///
public final class BlazeRemote: Remote, BlazeRemoteProtocol {

    public func loadCampaigns(for siteID: Int64, pageNumber: Int) async throws -> [BlazeCampaign] {
        let path = Paths.campaignSearch(siteID: siteID)
        let parameters: [String: Any] = [
            Keys.page: pageNumber,
            Keys.orderBy: Values.postDate, // change this if we have other options for ordering
            Keys.order: Values.desc // change this if we have other options for ordering
        ]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = BlazeCampaignListMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

}

private extension BlazeRemote {
    enum Paths {
        static func campaignSearch(siteID: Int64) -> String {
            "sites/\(siteID)/wordads/dsp/api/v1/search/campaigns/site/\(siteID)"
        }
    }

    enum Keys {
        static let orderBy = "order_by"
        static let order =  "order"
        static let page = "page"
    }

    enum Values {
        static let postDate = "post_date"
        static let desc = "desc"
    }
}
