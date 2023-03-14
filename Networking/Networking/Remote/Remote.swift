import Combine
import Foundation
import protocol Alamofire.URLRequestConvertible

/// Represents a collection of Remote Endpoints
///
public class Remote: NSObject {

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
    func enqueue(_ request: Request) async throws {
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
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Enqueues the specified Network Request with a generic expected result type.
    ///
    /// - Parameter request: Request that should be performed.
    /// - Returns: The result from the JSON parsed response for the expected type.
    func enqueue<T: Decodable>(_ request: Request) async throws -> T {
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
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
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
    func enqueue<M: Mapper>(_ request: Request, mapper: M, completion: @escaping (M.Output?, Error?) -> Void) {
        network.responseData(for: request) { [weak self] (data, networkError) in
            guard let self = self else {
                return
            }

            guard let data = data else {
                completion(nil, networkError)
                return
            }

            do {
                let validator = request.responseDataValidator()
                try validator.validate(data: data)
                let parsed = try mapper.map(response: data)
                completion(parsed, nil)
            } catch {
                self.handleResponseError(error: error, for: request)
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
    func enqueue<M: Mapper>(_ request: Request, mapper: M,
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
                    DDLogError("<> Mapping Error: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
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
    func enqueue<M: Mapper>(_ request: Request, mapper: M) -> AnyPublisher<Result<M.Output, Error>, Never> {
        network.responseDataPublisher(for: request)
            .map { (result: Result<Data, Error>) -> Result<M.Output, Error> in
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
                    return .failure(error)
                }
            }
            .handleEvents(receiveOutput: { [weak self] result in
                if let dotcomError = result.failure as? DotcomError {
                    self?.handleResponseError(error: dotcomError, for: request)
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
    func enqueueMultipartFormDataUpload<M: Mapper>(_ request: Request,
                                                   mapper: M,
                                                   multipartFormData: @escaping (MultipartFormData) -> Void,
                                                   completion: @escaping (Result<M.Output, Error>) -> Void) {
        network.uploadMultipartFormData(multipartFormData: multipartFormData,
                                        to: request) { [weak self] (data, networkError) in
                                            guard let self = self else {
                                                return
                                            }

                                            guard let data = data else {
                                                completion(.failure(networkError ?? NetworkError.notFound))
                                                return
                                            }

                                            do {
                                                let validator = request.responseDataValidator()
                                                try validator.validate(data: data)
                                                let parsed = try mapper.map(response: data)
                                                completion(.success(parsed))
                                            } catch {
                                                self.handleResponseError(error: error, for: request)
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
    func enqueue<M: Mapper>(_ request: Request, mapper: M) async throws -> M.Output {
        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { [weak self] (result: Swift.Result<Data, Error>) in
                guard let self else { return }

                switch result {
                case .success(let data):
                    do {
                        let validator = request.responseDataValidator()
                        try validator.validate(data: data)
                        let parsed = try mapper.map(response: data)
                        continuation.resume(returning: parsed)
                    } catch {
                        DDLogError("<> Mapping Error: \(error)")
                        self.handleResponseError(error: error, for: request)
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
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
}

// MARK: - Constants!
//
public extension Remote {

    enum Default {
        public static let firstPageNumber: Int = 1
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
}
