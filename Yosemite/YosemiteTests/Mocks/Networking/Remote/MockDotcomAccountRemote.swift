import WordPressKit
import XCTest
@testable import Yosemite

/// Mock for `DotcomAccountRemoteProtocol`.
///
final class MockDotcomAccountRemote {
    /// Returns the value when `closeAccount` is called.
    private var closeAccountResult: Result<Void, NSError> = .success(())

    /// Returns the value as a publisher when `closeAccount` is called.
    func whenClosingAccount(thenReturn result: Result<Void, NSError>) {
        closeAccountResult = result
    }
}

extension MockDotcomAccountRemote: DotcomAccountRemoteProtocol {
    func closeAccount(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        switch closeAccountResult {
        case .success:
            success()
        case .failure(let error):
            failure(error)
        }
    }
}
