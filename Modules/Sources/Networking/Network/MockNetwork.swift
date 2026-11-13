import Combine
import Foundation
import Alamofire
import Synchronization


// `@unchecked` only because the class is not `final`: `MockDeferredNetwork` subclasses it. All mutable state is in `state`.
/// Network Mock: Allows us to simulate HTTP Responses.
///
class MockNetwork: Network, @unchecked Sendable {

    private struct State {
        /// Mapping between URL Suffix and JSON Mock responses (in a FIFO queue).
        ///
        var responseQueue = [String: Queue<String>]()

        /// Mapping between URL Suffix and JSON Mock responses (in a simple array).
        ///
        var responseMap = [String: String]()

        /// Mapping between URL Suffix and Error responses.
        ///
        var errorMap = [String: Error]()

        var requestsForResponseData = [URLRequestConvertible]()
        var responseHeaders: [String: String]?
        var simulatesJetpackTunnel = true
    }

    /// Should this instance use the responseQueue or responseMap
    ///
    private let useResponseQueue: Bool

    private let state = Mutex(State())

    /// Keeps a collection of all of the `responseData` requests.
    ///
    var requestsForResponseData: [URLRequestConvertible] {
        state.withLock { $0.requestsForResponseData }
    }

    /// Response headers to be returned with the response data.
    var responseHeaders: [String: String]? {
        get { state.withLock { $0.responseHeaders } }
        set { state.withLock { $0.responseHeaders = newValue } }
    }

    /// Whether Jetpack requests count as sent through the tunnel. Set to `false` to simulate a site the
    /// app reaches directly with an application password.
    ///
    var simulatesJetpackTunnel: Bool {
        get { state.withLock { $0.simulatesJetpackTunnel } }
        set { state.withLock { $0.simulatesJetpackTunnel = newValue } }
    }

    /// Number of notification objects in notifications-load-all.json file.
    ///
    static let notificationLoadAllJSONCount = 46

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

    func usesJetpackTunnel(for request: URLRequestConvertible) -> Bool {
        simulatesJetpackTunnel && request is JetpackRequest
    }

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
        recordRequest(request)

        if let error = error(for: request) {
            completion(.failure(error))
            return
        }

        guard let name = filename(for: request), let data = Loader.contentsOf(name) else {
            completion(.failure(NetworkError.notFound()))
            return
        }

        completion(.success(data))
    }

    func responseDataAndHeaders(for request: any URLRequestConvertible,
                                isolation: isolated (any Actor)?) async throws -> (Data, ResponseHeaders?) {
        recordRequest(request)

        if let error = error(for: request) {
            throw error
        }

        guard let name = filename(for: request), let data = Loader.contentsOf(name) else {
            throw NetworkError.notFound()
        }

        return (data, responseHeaders)
    }

    func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Swift.Result<Data, Error>, Never> {
        recordRequest(request)

        if let error = error(for: request) {
            return Just<Swift.Result<Data, Error>>(.failure(error)).eraseToAnyPublisher()
        }

        guard let name = filename(for: request), let data = Loader.contentsOf(name) else {
            return Just<Swift.Result<Data, Error>>(.failure(NetworkError.notFound())).eraseToAnyPublisher()
        }

        return Just<Swift.Result<Data, Error>>(.success(data)).eraseToAnyPublisher()
    }

    func uploadMultipartFormData(multipartFormData: @escaping (NetworkingCore.MultipartFormData) -> Void,
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
        state.withLock { $0.errorMap[requestUrlSuffix] = error }
    }

    /// Removes all of the stored Simulated Responses.
    ///
    func removeAllSimulatedResponses() {
        state.withLock {
            $0.responseMap.removeAll()
            $0.errorMap.removeAll()
        }
    }
}


// MARK: - Private Helpers
//
private extension MockNetwork {

    /// Adds the URL suffix and response JSON Filename to the response queue
    ///
    private func addResponseToQueue(requestUrlSuffix: String, filename: String) {
        state.withLock {
            if $0.responseQueue[requestUrlSuffix] == nil {
                $0.responseQueue[requestUrlSuffix] = Queue<String>()
            }
            $0.responseQueue[requestUrlSuffix]?.enqueue(filename)
        }
    }

    /// Adds the URL suffix and response JSON Filename to the response map
    ///
    private func addResponseToMap(requestUrlSuffix: String, filename: String) {
        state.withLock { $0.responseMap[requestUrlSuffix] = filename }
    }

    private func recordRequest(_ request: URLRequestConvertible) {
        state.withLock { $0.requestsForResponseData.append(request) }
    }

    /// Returns the Mock JSON Filename for a given URLRequestConvertible from either:
    ///
    ///   * the FIFO response queue (where the response is removed from the queue when this func returns)
    ///   * the responseMap (array)
    ///
    func filename(for request: URLRequestConvertible) -> String? {
        let searchPath = path(for: request)
        return state.withLock { state -> String? in
            if useResponseQueue {
                if let keyAndQueue = state.responseQueue.first(where: { searchPath.hasSuffix($0.key) }) {
                    return state.responseQueue[keyAndQueue.key]?.dequeue()
                }
            } else {
                if let filename = state.responseMap.filter({ searchPath.hasSuffix($0.key) })
                    // In cases where a suffix is a substring of another suffix, the longer suffix is preferred in matched results.
                    .max(by: { $0.key.count < $1.key.count })?.value {
                    return filename
                }
            }

            return nil
        }
    }

    /// Returns the Mock Error for a given URLRequestConvertible.
    ///
    private func error(for request: URLRequestConvertible) -> Error? {
        let searchPath = path(for: request)
        return state.withLock { state -> Error? in
            for (pattern, error) in state.errorMap where searchPath.hasSuffix(pattern) {
                return error
            }

            return nil
        }
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
        default:
            let targetURL = try! request.asURLRequest().url?.absoluteString
            return targetURL ?? ""
        }
    }
}
