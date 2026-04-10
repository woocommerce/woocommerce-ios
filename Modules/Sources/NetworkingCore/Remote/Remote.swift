import Combine
import Foundation
import protocol Alamofire.URLRequestConvertible

/// Represents a collection of Remote Endpoints
///
open class Remote: NSObject {

    /// Networking Wrapper: Dependency Injection Mechanism, useful for Unit Testing purposes.
    ///
    let network: Network

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - credentials: Credentials to be used in order to authenticate every request.
    ///     - network: Network Wrapper, in charge of actually enqueueing a given network request.
    ///
    public init(network: Network) {
        self.network = network
    }

    /// Enqueues the specified Network Request and return Void if successful.
    ///
    /// - Parameter request: Request that should be performed.
    ///
    public func enqueue(_ request: Request) async throws {
        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let data):
                    do {
                        let validator = request.responseDataValidator()
                        try validator.validate(data: data)
                        continuation.resume()
                    } catch {
                        self.handleResponseError(error: error, for: request)
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: self.mapNetworkError(error: error, for: request))
                }
            }
        }
    }

    /// Enqueues the specified Network Request with a generic expected result type.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: The result from the JSON parsed response for the expected type.
    public func enqueue<T: Decodable>(_ request: Request) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let data):
                    do {
                        let validator = request.responseDataValidator()
                        try validator.validate(data: data)
                        let document = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: document)
                    } catch {
                        self.handleResponseError(error: error, for: request)
                        self.handleDecodingError(error: error, for: request, entityName: "\(T.self)")
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: self.mapNetworkError(error: error, for: request))
                }
            }
        }
    }


    /// Enqueues the specified Network Request.
    ///
    /// - Important:
    ///     - Parsing will be performed by the Mapper.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - mapper: Mapper entity that will be used to attempt to parse the Backend's Response.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func enqueue<M: Mapper>(_ request: Request, mapper: M, completion: @escaping (M.Output?, Error?) -> Void) {
        network.responseData(for: request) { [weak self] (data, networkError) in
            guard let self = self else {
                return
            }

            guard let data = data else {
                let error: Error? = networkError.map { self.mapNetworkError(error: $0, for: request) }
                completion(nil, error)
                return
            }

            do {
                let validator = request.responseDataValidator()
                try validator.validate(data: data)
                let parsed = try mapper.map(response: data)
                completion(parsed, nil)
            } catch {
                self.handleResponseError(error: error, for: request)
                self.handleDecodingError(error: error, for: request, entityName: "\(M.Output.self)")
                DDLogError("<> Mapping Error: \(error)")
                completion(nil, error)
            }
        }
    }

    /// Enqueues the specified Network Request.
    ///
    /// - Important:
    ///     - Parsing will be performed by the Mapper.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - mapper: Mapper entity that will be used to attempt to parse the Backend's Response.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func enqueue<M: Mapper>(_ request: Request, mapper: M,
                            completion: @escaping (Result<M.Output, Error>) -> Void) {
        network.responseData(for: request) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let data):
                do {
                    let validator = request.responseDataValidator()
                    try validator.validate(data: data)
                    let parsed = try mapper.map(response: data)
                    completion(.success(parsed))
                } catch {
                    self.handleResponseError(error: error, for: request)
                    self.handleDecodingError(error: error, for: request, entityName: "\(M.Output.self)")
                    DDLogError("<> Mapping Error: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(self.mapNetworkError(error: error, for: request)))
            }
        }
    }

    /// Returns a publisher that enqueues the specified Network Request on subscription and emits the result upon completion.
    ///
    /// - Important:
    ///     - Parsing will be performed by the Mapper.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - mapper: Mapper entity that will be used to attempt to parse the Backend's Response.
    ///
    /// - Returns: A publisher that emits result upon completion.
    public func enqueue<M: Mapper>(_ request: Request, mapper: M) -> AnyPublisher<Result<M.Output, Error>, Never> {
        network.responseDataPublisher(for: request)
            .map { [weak self] (result: Result<Data, Error>) -> Result<M.Output, Error> in
                switch result {
                case .success(let data):
                    do {
                        let validator = request.responseDataValidator()
                        try validator.validate(data: data)
                        let parsed = try mapper.map(response: data)
                        return .success(parsed)
                    } catch {
                        DDLogError("<> Mapping Error: \(error)")
                        return .failure(error)
                    }
                case .failure(let error):
                    return .failure(self?.mapNetworkError(error: error, for: request) ?? error)
                }
            }
            .handleEvents(receiveOutput: { [weak self] result in
                if let dotcomError = result.failure as? DotcomError {
                    self?.handleResponseError(error: dotcomError, for: request)
                }
                if let decodingError = result.failure as? DecodingError {
                    self?.handleDecodingError(error: decodingError, for: request, entityName: "\(M.Output.self)")
                }
            })
            .eraseToAnyPublisher()
    }

    /// Enqueues the specified Network Request for upload with multipart form data encoding.
    ///
    /// - Important:
    ///     - Parsing will be performed by the Mapper.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - mapper: Mapper entitity that will be used to attempt to parse the Backend's Response.
    ///     - multipartFormData: Used for appending data for multipart form data uploads.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func enqueueMultipartFormDataUpload<M: Mapper>(_ request: Request,
                                                   mapper: M,
                                                   multipartFormData: @escaping (MultipartFormData) -> Void,
                                                   completion: @escaping (Result<M.Output, Error>) -> Void) {
        network.uploadMultipartFormData(multipartFormData: multipartFormData,
                                        to: request) { [weak self] (data, networkError) in
                                            guard let self = self else {
                                                return
                                            }

                                            guard let data = data else {
                                                completion(.failure(networkError ?? NetworkError.notFound()))
                                                return
                                            }

                                            do {
                                                let validator = request.responseDataValidator()
                                                try validator.validate(data: data)
                                                let parsed = try mapper.map(response: data)
                                                completion(.success(parsed))
                                            } catch {
                                                self.handleResponseError(error: error, for: request)
                                                self.handleDecodingError(error: error, for: request, entityName: "\(M.Output.self)")
                                                DDLogError("<> Mapping Error: \(error)")
                                                completion(.failure(error))
                                            }
        }
    }

    /// Enqueues the specified Network Request using Swift Concurrency.
    ///
    /// - Important:
    ///     - Parsing will be performed by the Mapper.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: The result from the JSON parsed response for the expected type.
    public func enqueue<M: Mapper>(_ request: Request, mapper: M) async throws -> M.Output {
        try await enqueueWithResponseHeaders(request, mapper: mapper).data
    }

    public func enqueueWithResponseHeaders<M: Mapper>(_ request: Request, mapper: M) async throws -> (data: M.Output, headers: [String: String]?) {
        do {
            let (data, headers) = try await network.responseDataAndHeaders(for: request)
            let validator = request.responseDataValidator()
            let parsedData = try validateAndParseData(data, request: request, validator: validator, mapper: mapper)
            return (data: parsedData, headers: headers)
        } catch {
            handleResponseError(error: error, for: request)
            throw mapNetworkError(error: error, for: request)
        }
    }

    /// Enqueues the specified Network Request using Swift Concurrency, for fetching the headers
    ///
    /// - Important:
    ///     - No data will be parsed. This is intended for use with `HEAD` requests, but will make whatever request you specify
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: The headers from the response
    public func enqueueWithResponseHeaders(_ request: Request) async throws -> [String: String] {
        do {
            let (_, headers) = try await network.responseDataAndHeaders(for: request)
            return headers ?? [:]
        } catch {
            handleResponseError(error: error, for: request)
            throw mapNetworkError(error: error, for: request)
        }
    }
}

private extension Remote {
    // Validation and parsing of the response data is separated so that the decoding error can be handled separately from network error.
    func validateAndParseData<M: Mapper>(_ data: Data, request: Request, validator: ResponseDataValidator, mapper: M) throws -> M.Output {
        do {
            try validator.validate(data: data)
            return try mapper.map(response: data)
        } catch {
            DDLogError("<> Mapping Error: \(error)")
            handleDecodingError(error: error, for: request, entityName: "\(M.Output.self)")
            throw error
        }
    }
}

// MARK: - Private Methods
//
private extension Remote {

    /// Handles *all* of the DotcomError(s) that are successfully parsed.
    ///
    func handleResponseError(error: Error, for request: Request) {
        guard let dotcomError = error as? DotcomError else {
            return
        }

        switch dotcomError {
        case .requestFailed where request is JetpackRequest:
            publishJetpackTimeoutNotification(error: dotcomError)
        case .invalidToken:
            publishInvalidTokenNotification(error: dotcomError)
        default:
            break
        }
    }

    /// Handles decoding errors when parsing the response data fails.
    ///
    func handleDecodingError(error: Error, for request: Request, entityName: String) {
        guard let decodingError = error as? DecodingError else {
            return
        }
        publishJSONParsingErrorNotification(error: decodingError, path: request.pathForAnalytics, entityName: entityName)
    }

    /// Maps an error from `network.responseData` so that the request's corresponding error can be returned.
    ///
    func mapNetworkError(error: Error, for request: Request) -> Error {
        guard let networkError = error as? NetworkError else {
            return error
        }

        /// We will to attempt to validate the error using `ResponseDataValidator`
        /// if the error has accompanied response data.
        ///
        guard let response = networkError.response else {
            return networkError
        }

        /// Pass the response to request's validator
        /// which will attempt to parse the response into corresponding error.
        ///
        /// For example, `DotcomValidator` will parse the response and throw `DotcomError`.
        ///
        do {
            let validator = request.responseDataValidator()
            try validator.validate(data: response)
            return networkError
        } catch {
            return error
        }
    }

    /// Publishes a `Jetpack Timeout` Notification.
    ///
    private func publishJetpackTimeoutNotification(error: DotcomError) {
        NotificationCenter.default.post(name: .RemoteDidReceiveJetpackTimeoutError, object: error, userInfo: nil)
    }

    /// Publishes an `Invalid Token` Notification.
    ///
    private func publishInvalidTokenNotification(error: DotcomError) {
        NotificationCenter.default.post(name: .RemoteDidReceiveInvalidTokenError, object: error, userInfo: nil)
    }

    /// Publishes a `JSON Parsing Error` Notification.
    ///
    private func publishJSONParsingErrorNotification(error: Error, path: String?, entityName: String) {
        NotificationCenter.default.post(name: .RemoteDidReceiveJSONParsingError, object: error, userInfo: [
            JSONParsingErrorUserInfoKey.path: path,
            JSONParsingErrorUserInfoKey.entityName: entityName
        ].compactMapValues { $0 })
    }
}

/// Contains the result of a paginated request.
public struct PagedItems<T> {
    /// Items fetched in this page
    public let items: [T]

    /// Whether there are more pages after this one
    public let hasMorePages: Bool

    /// Number of items available, across all pages, whether loaded or not
    public let totalItems: Int?

    public init(items: [T], hasMorePages: Bool, totalItems: Int?) {
        self.items = items
        self.hasMorePages = hasMorePages
        self.totalItems = totalItems
    }
}

// MARK: - Pagination Helpers
//
public extension Remote {
    /// Creates a PagedItems instance from response data and headers.
    ///
    /// - Parameters:
    ///   - items: The parsed items from the response.
    ///   - responseHeaders: HTTP response headers containing pagination info.
    ///   - currentPageNumber: The current page number for determining if more pages exist.
    /// - Returns: PagedItems instance with pagination metadata.
    func createPagedItems<T>(items: [T],
                             responseHeaders: [String: String]?,
                             currentPageNumber: Int) -> PagedItems<T> {
        // Extract total pages from response headers (case insensitive)
        let totalPages = responseHeaders?.first(where: {
            $0.key.lowercased() == PaginationHeaderKey.totalPagesCount.lowercased()
        }).flatMap { Int($0.value) }

        let hasMorePages = totalPages.map { currentPageNumber < $0 } ?? true

        let totalItems = totalItemsCount(from: responseHeaders)

        return PagedItems(items: items, hasMorePages: hasMorePages, totalItems: totalItems)
    }

    func totalItemsCount(from responseHeaders: [String: String]?) -> Int? {
        // Extract total count from response headers (case insensitive)
        responseHeaders?.first(where: {
            $0.key.lowercased() == PaginationHeaderKey.totalCount.lowercased()
        }).flatMap { Int($0.value) }
    }
}

// MARK: - Constants!
//
public extension Remote {

    enum Default {
        public static let firstPageNumber: Int = 1
    }

    enum PaginationHeaderKey {
        public static let totalPagesCount = "x-wp-totalpages"
        public static let totalCount = "x-wp-total"
    }

    enum JSONParsingErrorUserInfoKey {
        public static let path = "path"
        public static let entityName = "entity"
    }
}


// MARK: - Remote Notifications
//
public extension NSNotification.Name {

    /// Posted whenever an Invalid Token Error is received.
    ///
    static let RemoteDidReceiveInvalidTokenError = NSNotification.Name(rawValue: "RemoteDidReceiveInvalidTokenError")

    /// Posted whenever a Jetpack Timeout is received.
    ///
    static let RemoteDidReceiveJetpackTimeoutError = NSNotification.Name(rawValue: "RemoteDidReceiveJetpackTimeoutError")

    /// Posted whenever a Mapper fails to parse the response.
    ///
    static let RemoteDidReceiveJSONParsingError = NSNotification.Name(rawValue: "RemoteDidReceiveJSONParsingError")
}
