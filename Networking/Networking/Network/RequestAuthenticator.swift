import Alamofire
import Foundation

// TODO: Replace with actual implementation.
final class TemporaryApplicationPasswordUseCase: ApplicationPasswordUseCase {
    init(siteID: Int64, credentials: Credentials) {
        // no-op
    }

    var applicationPassword: ApplicationPassword? {
        return nil
    }

    func generateNewPassword() async throws -> ApplicationPassword {
        return .init(wpOrgUsername: "test", password: .init("12345"))
    }

    func deletePassword() async throws {
        // no-op
    }
}

/// Helper class to update requests with authorization header if possible.
///
final class RequestAuthenticator {
    /// WordPress.com Credentials.
    ///
    private let credentials: Credentials?

    /// The use case to handle authentication with application passwords.
    ///
    private var applicationPasswordUseCase: ApplicationPasswordUseCase?

    init(credentials: Credentials?) {
        self.credentials = credentials
    }

    /// Updates the application password use case with a new site ID.
    ///
    func updateApplicationPasswordHandler(with useCase: ApplicationPasswordUseCase) {
        applicationPasswordUseCase = useCase
    }

    /// Updates a request with application password or WPCOM token if possible.
    ///
    func authenticateRequest(_ request: URLRequestConvertible, completion: @escaping (URLRequestConvertible) -> Void) {
        guard let restRequest = request as? RESTRequest,
              let useCase = applicationPasswordUseCase else {
            // Handle non-REST requests as before
            return completion(authenticateUsingWPCOMTokenIfPossible(request))
        }
        Task(priority: .medium) {
            let result = await authenticateUsingApplicationPassword(restRequest, useCase: useCase)
            await MainActor.run {
                completion(result)
            }
        }
    }

    /// Attempts authenticating a request with application password.
    ///
    private func authenticateUsingApplicationPassword(_ restRequest: RESTRequest, useCase: ApplicationPasswordUseCase) async -> URLRequestConvertible {
        do {
            let applicationPassword: ApplicationPassword = try await {
                if let password = useCase.applicationPassword {
                    return password
                }
                return try await useCase.generateNewPassword()
            }()
            return try await MainActor.run {
                return try restRequest.authenticateRequest(with: applicationPassword)
            }
        } catch {
            DDLogWarn("⚠️ Error generating application password and update request: \(error)")
            // TODO: add Tracks
            // Get the fallback Jetpack request to handle if possible.
            let fallbackRequest: URLRequestConvertible = restRequest.fallbackRequest ?? restRequest
            return authenticateUsingWPCOMTokenIfPossible(fallbackRequest)
        }
    }

    /// Attempts creating a request with WPCOM token if possible.
    ///
    private func authenticateUsingWPCOMTokenIfPossible(_ request: URLRequestConvertible) -> URLRequestConvertible {
        credentials.map { AuthenticatedRequest(credentials: $0, request: request) } ??
        UnauthenticatedRequest(request: request)
    }
}
