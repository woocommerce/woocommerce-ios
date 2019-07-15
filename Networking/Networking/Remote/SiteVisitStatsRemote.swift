import Foundation
import Alamofire

/// SiteVisitStats: Remote Endpoints
///
public class SiteVisitStatsRemote: Remote {

    /// Fetch the visitor stats for a given site up to the current day, week, month, or year (depending on the given granularity of the `unit` parameter).
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'day', 'week', 'month', or 'year')
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - quantity: How many `unit`s to fetch
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSiteVisitorStats(for siteID: Int,
                                     unit: StatGranularity,
                                     latestDateToInclude: Date,
                                     quantity: Int,
                                     completion: @escaping (SiteVisitStats?, SiteVisitStatsRemoteError?) -> Void) {
        let path = "\(Constants.sitesPath)/\(siteID)/\(Constants.siteVisitStatsPath)/"
        let parameters = [ParameterKeys.unit: unit.rawValue,
                          ParameterKeys.date: DateFormatter.Stats.statsDayFormatter.string(from: latestDateToInclude),
                          ParameterKeys.quantity: String(quantity),
                          ParameterKeys.statFields: Constants.visitorStatFieldValue]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SiteVisitStatsMapper()
        enqueue(request, mapper: mapper, completion: { siteVisitStats, error in
            if let error = error {
                completion(siteVisitStats, SiteVisitStatsRemoteError(error: error))
                return
            }
            completion(siteVisitStats, nil)
        })
    }
}


// MARK: - Constants!
//
private extension SiteVisitStatsRemote {
    enum Constants {
        static let sitesPath: String             = "sites"
        static let siteVisitStatsPath: String    = "stats/visits"
        static let visitorStatFieldValue: String = "visitors"
    }

    enum ParameterKeys {
        static let unit: String       = "unit"
        static let date: String       = "date"
        static let quantity: String   = "quantity"
        static let statFields: String = "stat_fields"
    }
}

/// An error that occurs at site visit stats networking layer.
/// API documentation of possible errors:
/// https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/stats/
///
public enum SiteVisitStatsRemoteError: Error {
    case statsModuleDisabled
    case unknown

    private enum ErrorIdentifiers {
        static let invalidBlog: String = "invalid_blog"
    }

    private enum ErrorMessages {
        static let statsModuleDisabled: String = "This blog does not have the Stats module enabled"
    }

    init(error: Error) {
        guard let dotcomError = error as? DotcomError else {
            self = .unknown
            return
        }
        switch dotcomError {
        case .unknown(let code, let message):
            if code == ErrorIdentifiers.invalidBlog && message == ErrorMessages.statsModuleDisabled {
                self = .statsModuleDisabled
            } else {
                self = .unknown
            }
        default:
            self = .unknown
        }
    }
}
