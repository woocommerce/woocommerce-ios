import WordPressKit
import XCTest
@testable import Yosemite

/// Mock for `DotcomAccountRemoteProtocol`.
///
final class MockDotcomAccountRemote {
    /// Returns the value when `disconnectFromSocialService` is called.
    var disconnectFromSocialServiceResult: Result<Void, NSError> = .success(())

    /// Returns the value as a publisher when `disconnectFromSocialService` is called.
    func whenDisconnectingFromSocialService(thenReturn result: Result<Void, NSError>) {
        disconnectFromSocialServiceResult = result
    }
}

extension MockDotcomAccountRemote: DotcomAccountRemoteProtocol {
    func disconnectFromSocialService(_ service: SocialServiceName,
                                     oAuthClientID: String,
                                     oAuthClientSecret: String,
                                     success: @escaping () -> Void,
                                     failure: @escaping (NSError) -> Void) {
        switch disconnectFromSocialServiceResult {
        case .success:
            success()
        case .failure(let error):
            failure(error)
        }
    }
}
