import Foundation
@testable import WordPressAuthenticator

class MockOnePasswordFacade: OnePasswordResultsFetcher {
    private struct Parameters {
      let username: String
      let password: String
      let otp: String?
    }

    private let result: Result<Parameters, OnePasswordError>

    init(username: String, password: String, otp: String?) {
      result = .success(Parameters(username: username, password: password, otp: otp))
    }

    init(error: OnePasswordError) {
      result = .failure(error)
    }

    func findLogin(for url: String, viewController: UIViewController, sender: Any, success: @escaping (String, String, String?) -> Void, failure: @escaping (OnePasswordError) -> Void) {
      switch result {
        case .failure(let error): failure(error)
        case .success(let parameters): success(parameters.username, parameters.password, parameters.otp)
      }
    }
}
