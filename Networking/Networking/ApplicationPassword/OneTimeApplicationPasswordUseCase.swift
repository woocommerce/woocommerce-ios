import Foundation
import KeychainAccess

/// Use case to save application password generated from web view;
/// The password will not be re-generated or deleted because no cookie authentication is available.
///
final public class OneTimeApplicationPasswordUseCase: ApplicationPasswordUseCase {
    public let applicationPassword: ApplicationPassword?

    private let network: Network
    private let siteAddress: String
    private let appID: String

    public init(applicationPassword: ApplicationPassword,
                siteAddress: String,
                credentials: Credentials,
                keychain: Keychain = Keychain(service: WooConstants.keychainServiceName)) {
        self.applicationPassword = applicationPassword
        self.siteAddress = siteAddress
        self.appID = applicationPassword.uuid
        self.network = AlamofireNetwork(credentials: credentials)
        let storage = ApplicationPasswordStorage(keychain: keychain)
        storage.saveApplicationPassword(applicationPassword)
    }

    public func generateNewPassword() async throws -> ApplicationPassword {
        throw ApplicationPasswordUseCaseError.unauthorizedRequest
    }

    public func deletePassword() async throws {
        let request = RESTRequest(siteURL: siteAddress, method: .delete, path: Path.applicationPasswords + "/" + appID)

        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension OneTimeApplicationPasswordUseCase {
    enum Path {
        static let applicationPasswords = "wp/v2/users/me/application-passwords"
    }
}
