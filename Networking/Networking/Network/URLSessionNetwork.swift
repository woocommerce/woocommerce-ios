import Combine
import Foundation

/// A network to handle requests using a native session manager.
///
public final class URLSessionNetwork: Network {
    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials?
    private let sessionManager: SessionManager = .default

    public var session: URLSession { sessionManager.session }

    public required init(credentials: Credentials?) {
        self.credentials = credentials
    }

    public func responseData(for request: Request, completion: @escaping (Data?, Error?) -> Void) {
        let request = createRequest(wrapping: request)
        Task(priority: .medium) {
            do {
                let data = try await sessionManager.request(request)
                await MainActor.run {
                    completion(data, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    public func responseData(for request: Request, completion: @escaping (Result<Data, Error>) -> Void) {
        let request = createRequest(wrapping: request)
        Task(priority: .medium) {
            do {
                let data = try await sessionManager.request(request)
                await MainActor.run {
                    completion(.success(data))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    public func responseDataPublisher(for request: Request) -> AnyPublisher<Result<Data, Error>, Never> {
        let request = createRequest(wrapping: request)
        return Future() { promise in
            Task(priority: .medium) {
                do {
                    let data = try await self.sessionManager.request(request)
                    await MainActor.run {
                        promise(Result.success(.success(data)))
                    }
                } catch {
                    await MainActor.run {
                        promise(Result.success(.failure(error)))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    public func uploadMultipartFormData(
        multipartFormData: @escaping (MultipartFormDataType) -> Void,
        to request: Request,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        let request = createRequest(wrapping: request)
        Task(priority: .low) {
            do {
                let data = try await sessionManager.upload(multipartFormData: multipartFormData, with: request)
                await MainActor.run {
                    completion(data, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }
}

private extension URLSessionNetwork {
    func createRequest(wrapping request: Request) -> Request {
        credentials.map { AuthenticatedRequest(credentials: $0, request: request) } ??
        UnauthenticatedRequest(request: request)
    }
}
