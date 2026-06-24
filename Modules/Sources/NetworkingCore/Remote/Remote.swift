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
        do {
            // `responseDataAndHeaders` is a `nonisolated async` call, so validation runs on the
            // cooperative pool (off the main thread) when it resumes.
            let (data, _) = try await network.responseDataAndHeaders(for: request)
            try request.responseDataValidator().validate(data: data)
        } catch {
            handleResponseError(error: error, for: request)
            throw mapNetworkError(error: error, for: request)
        }
    }

    /// Enqueues the specified Network Request with a generic expected result type.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: The result from the JSON parsed response for the expected type.
    public func enqueue<T: Decodable>(_ request: Request) async throws -> T {
        do {
            // `responseDataAndHeaders` is a `nonisolated async` call, so validation and decoding run
            // on the cooperative pool (off the main thread) when it resumes.
            let (data, _) = try await network.responseDataAndHeaders(for: request)
            try request.responseDataValidator().validate(data: data)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            handleResponseError(error: error, for: request)
            handleDecodingError(error: error, for: request, entityName: "\(T.self)")
            throw mapNetworkError(error: error, for: request)
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
        network.responseData(for: request) { [weak self] data, networkError in
            guard let self else {
                return
            }

            guard let data else {
                let error: Error? = networkError.map { self.mapNetworkError(error: $0, for: request) }
                completion(nil, error)
                return
            }

            self.parseResponseInBackground(data, request: request, mapper: mapper) { result in
                switch result {
                case .success(let parsed):
                    completion(parsed, nil)
                case .failure(let error):
                    completion(nil, error)
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
    public func enqueue<M: Mapper>(_ request: Request, mapper: M,
                            completion: @escaping (Result<M.Output, Error>) -> Void) {
        network.responseData(for: request) { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success(let data):
                self.parseResponseInBackground(data, request: request, mapper: mapper, completion: completion)
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
        Future { [weak self] promise in
            guard let self else {
                return
            }
            self.network.responseData(for: request) { [weak self] (result: Swift.Result<Data, Error>) in
                guard let self else {
                    return
                }

                switch result {
                case .success(let data):
                    self.parseResponseInBackground(data, request: request, mapper: mapper) { parsed in
                        promise(.success(parsed))
                    }
                case .failure(let error):
                    let mappedError = self.mapNetworkError(error: error, for: request)
                    DispatchQueue.main.async {
                        if let dotcomError = mappedError as? DotcomError {
                            self.handleResponseError(error: dotcomError, for: request)
                        }
                        promise(.success(.failure(mappedError)))
                    }
                }
            }
        }
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
                                        to: request) { [weak self] data, networkError in
                                            guard let self else {
                                                return
                                            }

                                            guard let data else {
                                                completion(.failure(networkError ?? NetworkError.notFound()))
                                                return
                                            }

                                            self.parseResponseInBackground(data, request: request, mapper: mapper, completion: completion)
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
            let parsedData = try validateAndParseData(data, request: request, mapper: mapper)
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
    /// Validates the response and maps it via the mapper. Shared by the off-main and the
    /// header-returning parse paths so validation + mapping lives in one place.
    static func validateAndMap<M: Mapper>(_ data: Data, request: Request, mapper: M) throws -> M.Output {
        try request.responseDataValidator().validate(data: data)
        return try mapper.map(response: data)
    }

    /// Validates and maps `data` on a background queue, then delivers the result — and any error
    /// handling/notifications — back on the main queue.
    func parseResponseInBackground<M: Mapper>(_ data: Data,
                                              request: Request,
                                              mapper: M,
                                              completion: @escaping (Result<M.Output, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result: Result<M.Output, Error>
            do {
                result = .success(try Self.validateAndMap(data, request: request, mapper: mapper))
            } catch {
                result = .failure(error)
            }

            DispatchQueue.main.async {
                if case let .failure(error) = result {
                    self?.handleResponseError(error: error, for: request)
                    self?.handleDecodingError(error: error, for: request, entityName: "\(M.Output.self)")
                    DDLogError("<> Mapping Error: \(error)")
                }
                completion(result)
            }
        }
    }

    // Validation and parsing of the response data is separated so that the decoding error can be handled separately from network error.
    func validateAndParseData<M: Mapper>(_ data: Data, request: Request, mapper: M) throws -> M.Output {
        do {
            return try Self.validateAndMap(data, request: request, mapper: mapper)
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
        case .unknownBlog:
            publishUnknownBlogNotification(error: dotcomError)
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

    /// Publishes an `Unknown Blog` Notification.
    ///
    private func publishUnknownBlogNotification(error: DotcomError) {
        NotificationCenter.default.post(name: .RemoteDidReceiveUnknownBlogError, object: error, userInfo: nil)
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

    /// The server's clock at the moment it served this page, parsed from the HTTP `Date` response
    /// header. `nil` if the header is absent or unparseable.
    public let serverDate: Date?

    public init(items: [T], hasMorePages: Bool, totalItems: Int?, serverDate: Date? = nil) {
        self.items = items
        self.hasMorePages = hasMorePages
        self.totalItems = totalItems
        self.serverDate = serverDate
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

        return PagedItems(items: items,
                          hasMorePages: hasMorePages,
                          totalItems: totalItems,
                          serverDate: serverDate(from: responseHeaders))
    }

    func totalItemsCount(from responseHeaders: [String: String]?) -> Int? {
        // Extract total count from response headers (case insensitive)
        responseHeaders?.first(where: {
            $0.key.lowercased() == PaginationHeaderKey.totalCount.lowercased()
        }).flatMap { Int($0.value) }
    }

    /// Parses the HTTP `Date` response header (e.g. `Tue, 15 Jun 2026 10:30:00 GMT`) into a `Date`.
    /// Returns `nil` if the header is absent or doesn't match the format we expect from the server.
    func serverDate(from responseHeaders: [String: String]?) -> Date? {
        responseHeaders?.first(where: {
            $0.key.lowercased() == PaginationHeaderKey.serverDate.lowercased()
        }).flatMap { Self.httpDateFormatter.date(from: $0.value) }
    }
}

private extension Remote {
    /// Formatter for the HTTP `Date` header as the server currently sends it
    /// (e.g. `Tue, 15 Jun 2026 10:30:00 GMT`). Fixed `en_US_POSIX` locale + GMT so parsing does not
    /// depend on the device's locale or time zone. If the server's date format changes, update the
    /// format string to match what we actually receive.
    static let httpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter
    }()
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
        /// Standard HTTP `Date` response header — the server's clock when it served the response.
        public static let serverDate = "date"
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

    /// Posted whenever an Unknown Blog Error is received, indicating the selected site ID is no longer recognized.
    ///
    static let RemoteDidReceiveUnknownBlogError = NSNotification.Name(rawValue: "RemoteDidReceiveUnknownBlogError")

    /// Posted whenever a Jetpack Timeout is received.
    ///
    static let RemoteDidReceiveJetpackTimeoutError = NSNotification.Name(rawValue: "RemoteDidReceiveJetpackTimeoutError")

    /// Posted whenever a Mapper fails to parse the response.
    ///
    static let RemoteDidReceiveJSONParsingError = NSNotification.Name(rawValue: "RemoteDidReceiveJSONParsingError")
}
