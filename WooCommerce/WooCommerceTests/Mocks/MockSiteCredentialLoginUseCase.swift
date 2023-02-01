import Foundation
import protocol Yosemite.StoresManager
@testable import WooCommerce

final class MockSiteCredentialLoginUseCase: SiteCredentialLoginProtocol {
    private let onLoading: (Bool) -> Void
    private let onLoginSuccess: () -> Void
    private let onLoginFailure: (WooCommerce.SiteCredentialLoginError) -> Void

    var mockedLoadingState: Bool?
    var shouldMockLoginSuccess: Bool = false
    var mockedLoginError: SiteCredentialLoginError?
    
    init(siteURL: String,
         stores: StoresManager,
         onLoading: @escaping (Bool) -> Void,
         onLoginSuccess: @escaping () -> Void,
         onLoginFailure: @escaping (WooCommerce.SiteCredentialLoginError) -> Void) {
        self.onLoading = onLoading
        self.onLoginSuccess = onLoginSuccess
        self.onLoginFailure = onLoginFailure
    }
    
    func handleLogin(username: String, password: String) {
        if let mockedLoadingState {
            onLoading(mockedLoadingState)
        } else if let mockedLoginError {
            onLoginFailure(mockedLoginError)
        } else if shouldMockLoginSuccess {
            onLoginSuccess()
        }
    }
}
