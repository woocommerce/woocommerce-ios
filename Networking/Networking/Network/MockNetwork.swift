import Combine
import Foundation
import Alamofire


/// Network Mock: Allows us to simulate HTTP Responses.
///
class MockNetwork: Network {

    /// Should this instance use the responseQueue or responseMap
    ///
    private var useResponseQueue: Bool = false

    /// Mapping between URL Suffix and JSON Mock responses (in a FIFO queue).
    ///
    private var responseQueue = [String: Queue<String>]()

    /// Mapping between URL Suffix and JSON Mock responses (in a simple array).
    ///
    private var responseMap = [String: String]()

    /// Mapping between URL Suffix and Error responses.
    ///
    private var errorMap = [String: Error]()

    /// Keeps a collection of all of the `responseData` requests.
    ///
    var requestsForResponseData = [URLRequestConvertible]()

    /// Note: If the useResponseQueue param is `true`, any responses added via `simulateResponse` will stored in a FIFO queue
    /// and used once for a matching request (then removed from the queue). Subsequent requests will use the next response in the queue, and so on.
    ///
    /// If the useResponseQueue param is `false`, any responses added via `simulateResponse` will stored in an array and can
    /// be reused multiple times.
    ///
    /// - Parameter useResponseQueue: Use the response queue. Default is `false`.
    ///
    init(useResponseQueue: Bool = false) {
        self.useResponseQueue = useResponseQueue
    }

    var session: URLSession { URLSession(configuration: .default) }

    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the specified response file, loaded as *Data*.
    /// Otherwise, an error will be relayed back (.notFound!).
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        responseData(for: request) { result in
            switch result {
            case .success(let data):
                completion(data, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the
    /// specified response file, loaded as *Data*. Otherwise, an error will be relayed back (.notFound!).
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Swift.Result<Data, Error>) -> Void) {
        requestsForResponseData.append(request)

        if let error = error(for: request) {
            completion(.failure(error))
            return
        }

        guard let name = filename(for: request), let data = Loader.contentsOf(name) else {
            completion(.failure(NetworkError.notFound))
            return
        }

        completion(.success(data))
    }

    func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Swift.Result<Data, Error>, Never> {
        requestsForResponseData.append(request)

        if let error = error(for: request) {
            return Just<Swift.Result<Data, Error>>(.failure(error)).eraseToAnyPublisher()
        }

        guard let name = filename(for: request), let data = Loader.contentsOf(name) else {
            return Just<Swift.Result<Data, Error>>(.failure(NetworkError.notFound)).eraseToAnyPublisher()
        }

        return Just<Swift.Result<Data, Error>>(.success(data)).eraseToAnyPublisher()
    }

    func uploadMultipartFormData(multipartFormData: @escaping (MultipartFormData) -> Void,
                                 to request: URLRequestConvertible,
                                 completion: @escaping (Data?, Error?) -> Void) {
        responseData(for: request, completion: completion)
    }
}


// MARK: - Public Methods
//
extension MockNetwork {

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
private extension MockNetwork {

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

    /// Returns the Mock JSON Filename for a given URLRequestConvertible from either:
    ///
    ///   * the FIFO response queue (where the response is removed from the queue when this func returns)
    ///   * the responseMap (array)
    ///
    func filename(for request: URLRequestConvertible) -> String? {
        let searchPath = path(for: request)
        if useResponseQueue {
            if let keyAndQueue = responseQueue.first(where: { searchPath.hasSuffix($0.key) }) {
                return responseQueue[keyAndQueue.key]?.dequeue()
            }
        } else {
            if let filename = responseMap.filter({ searchPath.hasSuffix($0.key) })
                // In cases where a suffix is a substring of another suffix, the longer suffix is preferred in matched results.
                .sorted(by: { $0.key.count > $1.key.count })
                .first?.value {
                return filename
            }
        }

        return nil
    }

    /// Returns the Mock Error for a given URLRequestConvertible.
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
        case let request as AuthenticatedDotcomRequest:
            return path(for: request.request)
        case let request as AuthenticatedRESTRequest:
            return path(for: request.request)
        case let request as UnauthenticatedRequest:
            return path(for: request.request)
        case let request as JetpackRequest:
            return request.path
        case let request as DotcomRequest:
            return request.path
        case let request as RESTRequest:
            return request.path
        default:
            let targetURL = try! request.asURLRequest().url?.absoluteString
            return targetURL ?? ""
        }
    }
}
