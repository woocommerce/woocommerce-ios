import Foundation

/// Interface for remote requests to Google Listings & Ads plugin.
///
public protocol GoogleListingsAndAdsRemoteProtocol {
    /// Check Google ads connection for the given site.
    ///
    func checkConnection(for siteID: Int64) async throws -> GoogleAdsConnection
}

/// Google Listings & Ads: Endpoints
///
public final class GoogleListingsAndAdsRemote: Remote, GoogleListingsAndAdsRemoteProtocol {

    public func checkConnection(for siteID: Int64) async throws -> GoogleAdsConnection {
        let path = Paths.connection
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        let mapper = GoogleAdsConnectionMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

private extension GoogleListingsAndAdsRemote {
    enum Paths {
        static let connection = "wc/gla/ads/connection"
    }
}
