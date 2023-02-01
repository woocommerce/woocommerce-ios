import Foundation
import protocol Yosemite.StoresManager
@testable import WooCommerce

final class MockSiteCredentialLoginUseCase: SiteCredentialLoginProtocol {
    private var onLoading: ((Bool) -> Void)?
    private var onLoginSuccess: (() -> Void)?
    private var onLoginFailure: ((WooCommerce.SiteCredentialLoginError) -> Void)?

    var mockedLoadingState: Bool?
    var shouldMockLoginSuccess: Bool = false
    var mockedLoginError: SiteCredentialLoginError?

    func setupHandlers(onLoading: @escaping (Bool) -> Void,
                       onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void) {
        self.onLoading = onLoading
        self.onLoginSuccess = onLoginSuccess
        self.onLoginFailure = onLoginFailure
    }

    func handleLogin(username: String, password: String) {
        if let mockedLoadingState {
            onLoading?(mockedLoadingState)
        } else if let mockedLoginError {
            onLoginFailure?(mockedLoginError)
        } else if shouldMockLoginSuccess {
            onLoginSuccess?()
        }
    }
}
