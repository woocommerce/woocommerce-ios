import Foundation
import Alamofire
@testable import Networking


/// Network Mockup: Allows us to simulate HTTP Responses.
///
class NetworkMockup: Network {

    /// Mapping between URL Suffix and JSON Mockup responses.
    ///
    private var responseMap = [String: String]()


    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the specified response.
    /// Otherwise, an error will be relayed back (.unavailable!).
    ///
    func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        guard let response = mockup(for: request) else {
            completion(nil, NetworkMockupError.unavailable)
            return
        }

        completion(response, nil)
    }
}

/// Public Methods
///
extension NetworkMockup {

    /// Whenever a request is enqueued, we'll return the specified JSON Encoded file, whenever the Request's URL suffix matches with
    /// the specified one.
    ///
    func simulateResponse(requestUrlSuffix: String, filename: String) {
        responseMap[requestUrlSuffix] = filename
    }

    /// Returns the Mockup JSON Response, provided that there's a mapping for the specified Request URL's Suffix.
    ///
    private func mockup(for request: URLRequestConvertible) -> Any? {
        guard let requestURL = try? request.asURLRequest().url, let urlAsString = requestURL?.absoluteString else {
            return nil
        }

        let simulated = responseMap.first { (suffix, _) -> Bool in
            urlAsString.hasSuffix(suffix)
        }

        guard let filename = simulated?.value else {
            return nil
        }

        return JSONLoader.load(filename: filename)
    }
}


/// NetworkMockup Errors
///
enum NetworkMockupError: Error {
    case unavailable
}
