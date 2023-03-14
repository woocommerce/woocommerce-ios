import Foundation
@testable import WooCommerce

/// Mock for `WordPressComAccountService`
final class MockWordPressComAccountService: WordPressComAccountServiceProtocol {
    var shouldReturnPasswordlessAccount: Bool = false
    var passwordlessAccountCheckError: Error?
    var authenticationLinkRequestError: Error?
    var triggeredIsPasswordlessAccount = false
    var triggeredRequestAuthenticationLink = false

    func isPasswordlessAccount(username: String, success: @escaping (Bool) -> Void, failure: @escaping (Error) -> Void) {
        triggeredIsPasswordlessAccount = true
        guard let passwordlessAccountCheckError else {
            return success(shouldReturnPasswordlessAccount)
        }
        failure(passwordlessAccountCheckError)
    }

    func requestAuthenticationLink(for email: String, jetpackLogin: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        triggeredRequestAuthenticationLink = true
        guard let authenticationLinkRequestError else {
            return success()
        }
        failure(authenticationLinkRequestError)
    }
}
