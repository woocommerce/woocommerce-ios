import Foundation
@testable import WordPressAuthenticator

class MockOnePasswordFacade: OnePasswordResultsFetcher {
    var error: OnePasswordError?
    var username: String?
    var password: String?
    var otp: String?
    
    init(username: String, password: String, otp: String?) {
        self.error = nil
        self.username = username
        self.password = password
        if let otp = otp {
            self.otp = otp
        } else {
            self.otp = nil
        }
    }
    
    init(error: OnePasswordError) {
        self.error = error
        self.username = nil
        self.password = nil
        self.otp = nil
    }
    
    
    func findLogin(for url: String, viewController: UIViewController, sender: Any, success: @escaping (String, String, String?) -> Void, failure: @escaping (OnePasswordError) -> Void) {
        if let error = error as NSError? {
            failure(OnePasswordError(error: error))
            return
        }
        
        guard let username = username, let password = password else {
            failure(.unknown)
            return
        }
        
        let oneTimePassword = otp
        success(username, password, oneTimePassword)
    }
    
    
}
