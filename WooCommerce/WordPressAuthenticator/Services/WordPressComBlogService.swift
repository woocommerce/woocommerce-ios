import Foundation

// MARK: - WordPress.com BlogService
//
class WordPressComBlogService {

    /// Returns a new anonymous instance of WordPressComRestApi.
    ///
    private var anonymousAPI: WordPressComRestApi {
        let userAgent = WordPressAuthenticator.shared.configuration.userAgent
        let baseUrl = WordPressAuthenticator.shared.configuration.wpcomAPIBaseURL
        return WordPressComRestApi(oAuthToken: nil, userAgent: userAgent, baseURL: baseUrl)
    }

    /// Retrieves the WordPressComSiteInfo instance associated to a WordPress.com Site Address.
    ///
    func fetchSiteInfo(for address: String, success: @escaping (WordPressComSiteInfo) -> Void, failure: @escaping (Error) -> Void) {
        let remote = BlogServiceRemoteREST(wordPressComRestApi: anonymousAPI, siteID: 0)

        remote.fetchSiteInfo(forAddress: address, success: { response in
            guard let response = response else {
                failure(WordPressComBlogServiceError.unknown)
                return
            }

            let site = WordPressComSiteInfo(remote: response)
            success(site)

        }, failure: { error in
            let result = error ?? WordPressComBlogServiceError.unknown
            failure(result)
        })
    }

     func fetchUnauthenticatedSiteInfoForAddress(for address: String, success: @escaping (WordPressComSiteInfo) -> Void, failure: @escaping (Error) -> Void) {
        let remote = BlogServiceRemoteREST(wordPressComRestApi: anonymousAPI, siteID: 0)
        remote.fetchUnauthenticatedSiteInfo(forAddress: address, success: { response in
            guard let response = response else {
                failure(WordPressComBlogServiceError.unknown)
                return
            }

            let site = WordPressComSiteInfo(remote: response)
            guard site.url != Constants.wordPressBlogURL else {
                failure(WordPressComBlogServiceError.invalidWordPressAddress)
                return
            }
            success(site)
        }, failure: { error in
            let result: Error = {
                /// Check whether the site is suspended on WordPress.com and can't be connected using Jetpack
                ///
                if let apiError = error as? WordPressAPIError<WordPressComRestApiEndpointError>,
                   case let .endpointError(endpointError) = apiError,
                   endpointError.apiErrorCode == "connection_disabled" {
                    return WordPressComBlogServiceError.wpcomSiteSuspended
                }

                return error ?? WordPressComBlogServiceError.unknown
            }()
            failure(result)
        })
    }
}

// MARK: - Nested Types
//
extension WordPressComBlogService {
    enum Constants {
        static let wordPressBlogURL = "https://wordpress.com/blog"
    }
}

public enum WordPressComBlogServiceError: Error {
    case unknown
    case invalidWordPressAddress
    /// Whether the site is suspended on WordPress.com and can't be connected using Jetpack
    ///
    case wpcomSiteSuspended
}
