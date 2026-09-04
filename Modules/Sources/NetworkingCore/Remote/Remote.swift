import Combine
import Foundation
import protocol Alamofire.URLRequestConvertible

/// Represents a collection of Remote Endpoints
///
open class Remote: NSObject {

    /// Networking Wrapper: Dependency Injection Mechanism, useful for Unit Testing purposes.
    ///
    let network: Network

    /// Jetpack Tunnel raw-body diagnostics logger.
    ///
    var jetpackTunnelRawBodyErrorLogger: JetpackTunnelRawBodyErrorLogging = JetpackTunnelRawBodyErrorLogger()

    /// Records which store, if any, is rejecting our requests with `rest_invalid_signature`.
    ///
    var storeConnectionErrorRecorder: StoreConnectionErrorRecording = StoreConnectionErrorMonitor.shared

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
        let data: Data
        do {
            data = try await network.responseData(for: request)
        } catch {
            throw mapNetworkError(error: error, for: request)
        }

        do {
            try Self.validateResponse(data, for: request, recorder: storeConnectionErrorRecorder, outcome: .succeeded)
        } catch {
            logJetpackTunnelRawBodyErrorIfPresent(responseData: data, request: request, transportStatus: nil)
            handleResponseError(error: error, for: request)
            throw error
        }
    }

    /// Enqueues the specified Network Request with a generic expected result type.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: The result from the JSON parsed response for the expected type.
    public func enqueue<T: Decodable>(_ request: Request) async throws -> T {
        let data: Data
        do {
            data = try await network.responseData(for: request)
        } catch {
            throw mapNetworkError(error: error, for: request)
        }

        do {
            try Self.validateResponse(data, for: request, recorder: storeConnectionErrorRecorder, outcome: .succeeded)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logJetpackTunnelRawBodyErrorIfPresent(responseData: data, request: request, transportStatus: nil)
            handleResponseError(error: error, for: request)
            handleDecodingError(error: error, for: request, entityName: "\(T.self)")
            throw error
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

            let outcome: ResponseOutcome = networkError.map { .failed($0) } ?? .succeeded
            self.parseResponse(data, request: request, mapper: mapper, outcome: outcome) { result in
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
                self.parseResponse(data, request: request, mapper: mapper, outcome: .succeeded, completion: completion)
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
                    self.parseResponse(data, request: request, mapper: mapper, outcome: .succeeded) { parsed in
                        promise(.success(parsed))
                    }
                case .failure(let error):
                    let mappedError = self.mapNetworkError(error: error, for: request)
                    if let dotcomError = mappedError as? DotcomError {
                        self.handleResponseError(error: dotcomError, for: request)
                    }
                    promise(.success(.failure(mappedError)))
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

                                            self.parseResponse(data,
                                                               request: request,
                                                               mapper: mapper,
                                                               // Uploads report only serialization
                                                               // failures, not error status codes, so
                                                               // their outcome cannot be trusted here.
                                                               outcome: .undetermined,
                                                               completion: completion)
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
            let (data, headers) = try await network.responseDataAndHeaders(for: request)
            do {
                // A 2xx is not enough on its own: the Jetpack tunnel answers with a healthy status and
                // an error body. The body decides whether the store is reachable, so it is validated
                // here even though this overload does not parse it.
                try Self.validateResponse(data, for: request, recorder: storeConnectionErrorRecorder, outcome: .succeeded)
            } catch {
                // Handled but deliberately not rethrown. This overload has never surfaced body-level
                // errors to its callers and widening that is a separate change, but now that the body is
                // read, an expired token or an unknown blog has to reach the notifications the rest of
                // the app listens for.
                handleResponseError(error: error, for: request)
                DDLogDebug("Response body error on a headers-only request: \(error)")
            }
            return headers ?? [:]
        } catch {
            handleResponseError(error: error, for: request)
            throw mapNetworkError(error: error, for: request)
        }
    }
}

/// What the network layer was able to tell us about a request's outcome, alongside its body.
///
/// The Jetpack tunnel answers with a body worth parsing even when the request failed, so the body on its
/// own never says whether the store is reachable. Some callers cannot report the outcome at all, and
/// those must not be read as the store answering normally.
///
private enum ResponseOutcome {
    /// The request completed without a transport error.
    case succeeded

    /// The request failed, with the error the caller reported if it had one.
    case failed(Error?)

    /// The caller cannot tell either way. Never counts as the store being reachable.
    case undetermined
}

private extension Remote {
    /// Validates the response and maps it via the mapper.
    static func validateAndMap<M: Mapper>(_ data: Data,
                                          request: Request,
                                          mapper: M,
                                          recorder: StoreConnectionErrorRecording?,
                                          outcome: ResponseOutcome) throws -> M.Output {
        try validateResponse(data, for: request, recorder: recorder, outcome: outcome)
        return try mapper.map(response: data)
    }

    /// Validates and maps `data` on a background queue, then delivers the result — and any error
    /// handling/notifications — back on the main queue.
    ///
    /// `outcome` is what the caller knows about the request itself, which is a different question from
    /// whether the body parsed: the Jetpack tunnel answers with a body worth parsing even when the status
    /// code says the request failed, so the store's reachability is judged on the outcome instead.
    ///
    func parseResponse<M: Mapper>(_ data: Data,
                                              request: Request,
                                              mapper: M,
                                              outcome: ResponseOutcome,
                                              completion: @escaping (Result<M.Output, Error>) -> Void) {
        // Read before hopping queues so the outcome is still recorded, and the completion still called,
        // if this remote goes away while the response is being parsed.
        let recorder = storeConnectionErrorRecorder
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result: Result<M.Output, Error>
            do {
                result = .success(try Self.validateAndMap(data,
                                                          request: request,
                                                          mapper: mapper,
                                                          recorder: recorder,
                                                          outcome: outcome))
            } catch {
                result = .failure(error)
            }

            DispatchQueue.main.async {
                if case let .failure(error) = result {
                    self?.logJetpackTunnelRawBodyErrorIfPresent(responseData: data, request: request, transportStatus: nil)
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
            return try Self.validateAndMap(data,
                                           request: request,
                                           mapper: mapper,
                                           recorder: storeConnectionErrorRecorder,
                                           outcome: .succeeded)
        } catch {
            logJetpackTunnelRawBodyErrorIfPresent(responseData: data, request: request, transportStatus: nil)
            DDLogError("<> Mapping Error: \(error)")
            handleDecodingError(error: error, for: request, entityName: "\(M.Output.self)")
            throw error
        }
    }
}

// MARK: - Private Methods
//
private extension Remote {

    func logJetpackTunnelRawBodyErrorIfPresent(responseData: Data?, request: Request, transportStatus: Int?) {
        guard request is JetpackRequest else {
            return
        }

        jetpackTunnelRawBodyErrorLogger.logIfNeeded(
            responseData: responseData,
            request: request,
            transportStatus: transportStatus
        )
    }

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

    /// Runs the request's validator over a response body, recording the outcome for the store the
    /// request was made against.
    ///
    /// This is the one point every response body passes through, whichever `enqueue` overload the
    /// caller used, so it is where a store is flagged as unreachable and — just as importantly — where
    /// the flag is cleared again once the store answers normally.
    ///
    /// Nothing outside this method may record a successful connection. Judging that per overload is what
    /// produced a run of bugs where a store was marked reachable off a failed request: only here are both
    /// halves of the evidence in hand, the body having been validated and the caller's own outcome.
    ///
    static func validateResponse(_ data: Data,
                                 for request: Request,
                                 recorder: StoreConnectionErrorRecording?,
                                 outcome: ResponseOutcome) throws {
        do {
            try request.responseDataValidator().validate(data: data)
        } catch {
            recordStoreConnectionFailure(error: error, for: request, recorder: recorder)
            throw error
        }

        // A body the validator had nothing to say about is not proof the store is reachable: this
        // validator ignores plenty of error shapes, so the request's own outcome decides.
        switch outcome {
        case .succeeded:
            guard let siteID = affectedSiteID(for: request) else {
                return
            }
            recorder?.recordSuccessfulConnection(siteID: siteID)
        case .failed(let error):
            recordStoreConnectionFailure(error: error, for: request, recorder: recorder)
        case .undetermined:
            break
        }
    }

    /// Flags the store as unreachable when the failure is the invalid signature error.
    ///
    /// The error reaches us in two shapes: parsed into a `DotcomError` when the response body carried
    /// it, and as a status code failure whose body names the code, which is what the Jetpack tunnel
    /// returns when it relays the site's own rejection.
    ///
    /// Both of those are flat bodies. The tunnel has a third shape, where the site's response is nested
    /// as stringified JSON under `data.raw_body`, and it is not unwrapped here. Every example of it we
    /// have, on iOS and on Android, is an unparseable HTML body behind a 502 or 503, which suggests the
    /// tunnel only falls back to it when it could not read the response as JSON at all. A well formed
    /// error like this one should never land there. If detection turns out to be missing stores in
    /// production, that assumption is the first thing to re-test:
    /// `JetpackTunnelRawBodyErrorLogger` already models the envelope shapes involved.
    ///
    static func recordStoreConnectionFailure(error: Error?, for request: Request, recorder: StoreConnectionErrorRecording?) {
        let isInvalidSignature: Bool = {
            if let dotcomError = error as? DotcomError, case .invalidSignature = dotcomError {
                return true
            }
            return (error as? NetworkError)?.errorCode == DotcomError.invalidSignatureCode
        }()

        guard isInvalidSignature, let siteID = affectedSiteID(for: request) else {
            return
        }
        recorder?.recordInvalidSignature(siteID: siteID)
    }

    /// The store a request was made against, when we can tell.
    ///
    /// Every store-scoped request is a `JetpackRequest` at this layer, so the site is named on both auth
    /// paths: the conversion to a direct REST call happens below `Remote`, in `AlamofireNetwork`. Only
    /// the tunneled path can actually come back with a signature failure, since a request authenticated
    /// with an application password is never signed, but that is a property of the error rather than a
    /// limit on what this can see.
    ///
    static func affectedSiteID(for request: Request) -> Int64? {
        (request as? JetpackRequest)?.siteID
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

        logJetpackTunnelRawBodyErrorIfPresent(
            responseData: response,
            request: request,
            transportStatus: networkError.responseCode
        )

        /// Pass the response to request's validator
        /// which will attempt to parse the response into corresponding error.
        ///
        /// For example, `DotcomValidator` will parse the response and throw `DotcomError`.
        ///
        do {
            let validator = request.responseDataValidator()
            try validator.validate(data: response)
            Self.recordStoreConnectionFailure(error: networkError, for: request, recorder: storeConnectionErrorRecorder)
            return networkError
        } catch {
            Self.recordStoreConnectionFailure(error: error, for: request, recorder: storeConnectionErrorRecorder)
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
