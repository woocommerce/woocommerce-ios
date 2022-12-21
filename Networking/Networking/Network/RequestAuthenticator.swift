import Alamofire
import Foundation

/// Helper class to update requests with authorization header if possible.
///
final class RequestAuthenticator {
    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials?

    /// The use case to handle authentication with application passwords.
    ///
    private let applicationPasswordUseCase: ApplicationPasswordUseCase?

    /// Sets up the authenticator with optional credentials and application password use case.
    /// `applicationPasswordUseCase` can be injected for unit tests.
    ///
    init(credentials: Credentials?, applicationPasswordUseCase: ApplicationPasswordUseCase? = nil) {
        self.credentials = credentials
        let useCase: ApplicationPasswordUseCase? = {
            if let applicationPasswordUseCase {
                return applicationPasswordUseCase
            } else if let credentials,
                      case let .wporg(username, password, siteAddress) = credentials {
                return try? DefaultApplicationPasswordUseCase(username: username,
                                                              password: password,
                                                              siteAddress: siteAddress)
            } else {
                return nil
            }
        }()
        self.applicationPasswordUseCase = useCase
    }

    /// Updates a request with application password or WPCOM token if possible.
    ///
    func authenticateRequest(_ request: URLRequestConvertible, completion: @escaping (Swift.Result<URLRequestConvertible, Error>) -> Void) {
        guard let jetpackRequest = request as? JetpackRequest,
              jetpackRequest.availableAsRESTRequest,
              let useCase = applicationPasswordUseCase,
              case let .some(.wporg(_, _, siteAddress)) = credentials else {
            // Handle non-REST requests as before
            return completion(.success(authenticateUsingWPCOMTokenIfPossible(request)))
        }

        let restRequest = jetpackRequest.createRESTRequest(with: siteAddress)
        Task(priority: .medium) {
            let result: Swift.Result<URLRequestConvertible, Error>
            do {
                let authenticatedRequest = try await authenticateUsingApplicationPassword(restRequest, useCase: useCase)
                result = .success(authenticatedRequest)
            } catch {
                result = .failure(error)
            }
            await MainActor.run {
                completion(result)
            }
        }
    }

    /// Attempts authenticating a request with application password.
    ///
    private func authenticateUsingApplicationPassword(_ restRequest: RESTRequest, useCase: ApplicationPasswordUseCase) async throws -> URLRequestConvertible {
        let applicationPassword: ApplicationPassword = try await {
            if let password = useCase.applicationPassword {
                return password
            }
            return try await useCase.generateNewPassword()
        }()
        return try await MainActor.run {
            return try restRequest.authenticateRequest(with: applicationPassword)
        }
    }

    /// Attempts creating a request with WPCOM token if possible.
    ///
    private func authenticateUsingWPCOMTokenIfPossible(_ request: URLRequestConvertible) -> URLRequestConvertible {
        credentials.map { AuthenticatedRequest(credentials: $0, request: request) } ??
        UnauthenticatedRequest(request: request)
    }
}
