import Foundation
import Alamofire



/// AlamofireWrapper: Encapsulates all of the Alamofire OP's
///
public class AlamofireNetwork: Network {

    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials


    /// Public Initializer
    ///
    public required init(credentials: Credentials) {
        self.credentials = credentials
    }

    /// Executes the specified Network Request. Upon completion, the payload will be sent back to the caller as a Data instance.
    ///
    /// - Important:
    ///     - Authentication Headers will be injected, based on the Network's Credentials.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    /// - Note:
    ///     - The response body will always be returned (when possible), even when there's a networking error.
    ///       This differs slightly from the standard Alamofire `.validate()` behavior, and it's required so that
    ///       the upper layers can properly detect "Jetpack Tunnel" Errors.
    ///     - Yes. We do the above because the Jetpack Tunnel endpoint doesn't properly relay the correct statusCode.
    ///
    public func responseData(for request: WooURLRequestConvertable, completion: @escaping (Data?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)
        let sessionManager = Alamofire.SessionManager.default

        if request.retryAttempts > 0 {
            sessionManager.retrier = NetworkRequestRetrier(maximumRetryAttempts: request.retryAttempts)
        }
        sessionManager.request(authenticated)
            .responseData { response in
                completion(response.value, response.networkingError)
            }
    }
}


/// MARK: - Alamofire.DataResponse: Private Methods
///
private extension Alamofire.DataResponse {

    /// Returns the Networking Layer Error (if any):
    ///
    ///     -   Whenever the statusCode is not within the [200, 300) range.
    ///     -   Whenever there's a `NSURLErrorDomain` error: Bad Certificate, Unreachable, Cancelled (and few others!)
    ///
    /// NOTE: that we're not doing the standard Alamofire Validation, because the stock routine, on error, will never relay
    /// back the response body. And since the Jetpack Tunneling API does not relay the proper statusCodes, we're left in
    /// the dark.
    ///
    /// Precisely: Request Timeout should be a 408, but we just get a 400, with the details in the response's body.
    ///
    var networkingError: Error? {

        // Passthru URL Errors: These are right there, even without calling Alamofire's validation.
        if let error = error as NSError?, error.domain == NSURLErrorDomain {
            return error
        }

        return response.flatMap { response in
            NetworkError(from: response.statusCode)
        }
    }
}


// MARK: - Alamofire.NetworkRequestRetrier
//
class NetworkRequestRetrier: RequestRetrier {

    // [Request url: Number of times retried]
    private var retriedRequests: [String: Int] = [:]
    private var maximumRetryAttempts: Int = 0

    /// Designated Initializer
    ///
    init(maximumRetryAttempts: Int) {
        self.maximumRetryAttempts = maximumRetryAttempts
    }

    internal func should(_ manager: SessionManager,
                         retry request: Request,
                         with error: Error,
                         completion: @escaping RequestRetryCompletion) {

        guard maximumRetryAttempts > 0 else {
            completion(false, 0.0) // don't retry
            return
        }
        guard request.task?.response == nil, let urlString = request.request?.url?.absoluteString else {
                removeCachedUrlRequest(url: request.request?.url?.absoluteString)
                completion(false, 0.0) // don't retry
                return
        }
        guard let retryCount = retriedRequests[urlString] else {
            retriedRequests[urlString] = 1
            completion(true, 1.0) // retry after 1 second
            return
        }

        if retryCount <= maximumRetryAttempts {
            retriedRequests[urlString] = retryCount + 1
            completion(true, 1.0) // retry after 1 second
            DDLogInfo("⌛️ Retrying network request.")
        } else {
            removeCachedUrlRequest(url: urlString)
            completion(false, 0.0) // don't retry
        }
    }

    private func removeCachedUrlRequest(url: String?) {
        guard let url = url else {
            return
        }

        retriedRequests.removeValue(forKey: url)
    }
}
