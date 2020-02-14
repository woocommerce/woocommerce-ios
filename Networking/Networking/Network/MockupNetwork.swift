import Foundation
import Alamofire


/// Network Mockup: Allows us to simulate HTTP Responses.
///
class MockupNetwork: Network {

    /// Should this instance use the responseQueue or responseMap
    ///
    private var useResponseQueue: Bool = false

    /// Mapping between URL Suffix and JSON Mockup responses (in a FIFO queue).
    ///
    private var responseQueue = [String: Queue<String>]()

    /// Mapping between URL Suffix and JSON Mockup responses (in a simple array).
    ///
    private var responseMap = [String: String]()

    /// Mapping between URL Suffix and Error responses.
    ///
    private var errorMap = [String: Error]()

    /// Keeps a collection of all of the `responseData` requests.
    ///
    var requestsForResponseData = [URLRequestConvertible]()


    /// Public Initializer
    ///
    required init(credentials: Credentials) { }

    /// Dummy convenience initializer. Remember: Real Network wrappers will allways need credentials!
    ///
    /// Note: If the useResponseQueue param is `true`, any repsonses added via `simulateResponse` will stored in a FIFO queue
    /// and used once for a matching request (then removed from the queue). Subsuquent requests will use the next response in the queue, and so on.
    ///
    /// If the useResponseQueue param is `false`, any repsonses added via `simulateResponse` will stored in an array and can
    /// be reused multiple times.
    ///
    /// - Parameter useResponseQueue: Use the response queue. Default is `false`.
    ///
    convenience init(useResponseQueue: Bool = false) {
        let dummy = Credentials(username: "", authToken: "", siteAddress: "")
        self.init(credentials: dummy)
        self.useResponseQueue = useResponseQueue
    }


    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the specified response file, loaded as *Data*.
    /// Otherwise, an error will be relayed back (.notFound!).
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        requestsForResponseData.append(request)

        if let error = error(for: request) {
            completion(nil, error)
            return
        }

        guard let name = filename(for: request), let data = Loader.contentsOf(name) else {
            completion(nil, NetworkError.notFound)
            return
        }

        completion(data, nil)
    }

    func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                 to request: URLRequestConvertible,
                                 completion: @escaping (Data?, Error?) -> Void) {
        responseData(for: request, completion: completion)
    }
}


// MARK: - Public Methods
//
extension MockupNetwork {

    /// Whenever a request is enqueued, we'll return the specified JSON Encoded file, whenever the Request's URL suffix matches with
    /// the specified one.
    ///
    func simulateResponse(requestUrlSuffix: String, filename: String) {
        if useResponseQueue {
            addResponseToQueue(requestUrlSuffix: requestUrlSuffix, filename: filename)
        } else {
            addResponseToMap(requestUrlSuffix: requestUrlSuffix, filename: filename)
        }
    }

    /// We'll return the specified Error, whenever a request matches the specified Suffix Criteria!
    ///
    func simulateError(requestUrlSuffix: String, error: Error) {
        errorMap[requestUrlSuffix] = error
    }

    /// Removes all of the stored Simulated Responses.
    ///
    func removeAllSimulatedResponses() {
        responseMap.removeAll()
        errorMap.removeAll()
    }
}


// MARK: - Private Helpers
//
private extension MockupNetwork {

    /// Adds the URL suffix and response JSON Filename to the response queue
    ///
    private func addResponseToQueue(requestUrlSuffix: String, filename: String) {
        if responseQueue[requestUrlSuffix] == nil {
            responseQueue[requestUrlSuffix] = Queue<String>()
        }
        responseQueue[requestUrlSuffix]?.enqueue(filename)
    }

    /// Adds the URL suffix and response JSON Filename to the response map
    ///
    private func addResponseToMap(requestUrlSuffix: String, filename: String) {
        responseMap[requestUrlSuffix] = filename
    }

    /// Returns the Mockup JSON Filename for a given URLRequestConvertible from either:
    ///
    ///   * the FIFO response queue (where the response is removed from the queue when this func returns)
    ///   * the responseMap (array)
    ///
    func filename(for request: URLRequestConvertible) -> String? {
        let searchPath = path(for: request)
        if useResponseQueue {
            if var queue = responseQueue.filter({ searchPath.hasSuffix($0.key) }).first?.value {
                return queue.dequeue()
            }
        } else {
            if let filename = responseMap.filter({ searchPath.hasSuffix($0.key) }).first?.value {
                return filename
            }
        }

        return nil
    }

    /// Returns the Mockup Error for a given URLRequestConvertible.
    ///
    private func error(for request: URLRequestConvertible) -> Error? {
        let searchPath = path(for: request)
        for (pattern, error) in errorMap where searchPath.hasSuffix(pattern) {
            return error
        }

        return nil
    }

    /// Returns the "Request Path" for a given URLRequestConvertible instance.
    ///
    private func path(for request: URLRequestConvertible) -> String {
        switch request {
        case let request as AuthenticatedRequest:
            return path(for: request.request)
        case let request as JetpackRequest:
            return request.path
        case let request as DotcomRequest:
            return request.path
        default:
            let targetURL = try! request.asURLRequest().url?.absoluteString
            return targetURL ?? ""
        }
    }
}
