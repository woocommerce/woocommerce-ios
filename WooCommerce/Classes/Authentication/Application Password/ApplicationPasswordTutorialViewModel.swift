import Foundation

/// View Model for the Application Password Tutorial.
///
struct ApplicationPasswordTutorialViewModel {

    static func friendlyErrorMessage(for error: Error) -> String {

        let genericMessage = NSLocalizedString("This is because we got an unexpected response from your site.",
                                               comment: "Generic reason for why the user could not login tin the application password tutorial screen")

        guard let loginError = error as? SiteCredentialLoginError else {
            return genericMessage
        }

        switch loginError {
        case .loginFailed(message: let message):
            return message
        case .invalidLoginResponse, .genericFailure:
            return genericMessage
        case .inaccessibleLoginPage, .inaccessibleAdminPage, .unacceptableStatusCode:
            return NSLocalizedString("This is likely because your store has some extra security steps in place.",
                                     comment: "Reason for why the user could not login tin the application password tutorial screen")
        case .invalidCredentials:
            return error.localizedDescription
        }
    }
}
