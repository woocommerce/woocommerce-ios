import Foundation
import WordPressShared

struct ApplicationPassword {
    /// WordPress org username that the application password belongs to
    ///
    let wpOrgUsername: String

    /// Application password
    ///
    let password: Secret<String>
}

protocol ApplicationPasswordUseCase {
    /// Returns the locally saved ApplicationPassword if available
    ///
    var applicationPassword: ApplicationPassword? { get }

    /// Generates new ApplicationPassword
    ///
    /// - Returns: Generated `ApplicationPassword` instance
    ///
    func generateNewPassword() async throws -> ApplicationPassword

    /// Deletes the application password
    ///
    ///  Deletes locally and also sends an API request to delete it from the site
    ///
    func deletePassword() async throws
}
