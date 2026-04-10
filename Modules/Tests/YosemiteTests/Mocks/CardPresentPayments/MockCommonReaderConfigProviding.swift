import Foundation

@testable import Yosemite

final class MockCommonReaderConfigProviding: CommonReaderConfigProviding {
    private(set) var currentSiteID: Int64?
    private(set) var didResetContext = false

    func fetchToken(completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success("mock_token"))
    }

    func fetchDefaultLocationID(completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success("mock_location"))
    }

    func setContext(siteID: Int64, remote: Yosemite.CardReaderCapableRemote) {
        currentSiteID = siteID
    }

    func resetContext() {
        currentSiteID = nil
        didResetContext = true
    }
}
