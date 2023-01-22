import Foundation

@testable import Yosemite

final class MockCommonReaderConfigProviding: CommonReaderConfigProviding {
    func fetchToken(completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success("mock_token"))
    }

    func fetchDefaultLocationID(completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success("mock_location"))
    }

    func setContext(siteID: Int64, remote: Yosemite.CardReaderCapableRemote) {
        // no-op
    }
}
