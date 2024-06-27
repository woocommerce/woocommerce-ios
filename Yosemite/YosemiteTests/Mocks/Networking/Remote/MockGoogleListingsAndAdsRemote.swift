import XCTest
import Networking

final class MockGoogleListingsAndAdsRemote {

    private var checkingConnectionResult: Result<GoogleAdsConnection, Error>?

    func whenCheckingConnection(thenReturn result: Result<GoogleAdsConnection, Error>) {
        checkingConnectionResult = result
    }
}

extension MockGoogleListingsAndAdsRemote: GoogleListingsAndAdsRemoteProtocol {
    func checkConnection(for siteID: Int64) async throws -> Networking.GoogleAdsConnection {
        guard let result = checkingConnectionResult else {
            XCTFail("Could not find result for checking GLA connection.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let connection):
            return connection
        case .failure(let error):
            throw error
        }
    }
}
