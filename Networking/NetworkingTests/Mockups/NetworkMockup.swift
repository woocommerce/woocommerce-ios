import Foundation
import Alamofire
@testable import Networking


/// Network Mockup: Allows us to simulate HTTP Responses.
///
class NetworkMockup: Network {

    /// Mapping between URL Suffix and JSON Mockup responses.
    ///
    private var responseMap = [String: String]()


    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the specified response, *PARSED* as json.
    /// Otherwise, an error will be relayed back (.unavailable!).
    ///
    func responseJSON(for request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        guard let filename = filename(for: request), let response = Loader.jsonObject(for: filename) else {
            completion(nil, NetworkMockupError.unavailable)
            return
        }

        completion(response, nil)
    }

    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the specified response file, loaded as *Data*.
    /// Otherwise, an error will be relayed back (.unavailable!).
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        guard let filename = filename(for: request), let data = Loader.contentsOf(filename) else {
            completion(nil, NetworkMockupError.unavailable)
            return
        }

        completion(data, nil)
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

    /// Returns the Mockup JSON Filename.
    ///
    private func filename(for request: URLRequestConvertible) -> String? {
        guard let requestURL = try? request.asURLRequest().url, let urlAsString = requestURL?.absoluteString else {
            return nil
        }

        let simulated = responseMap.first { (suffix, _) in
            urlAsString.hasSuffix(suffix)
        }

        return simulated?.value
    }
}


/// NetworkMockup Errors
///
enum NetworkMockupError: Error {
    case unavailable
}
