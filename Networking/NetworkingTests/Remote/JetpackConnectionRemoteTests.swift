import XCTest
@testable import Networking

final class JetpackConnectionRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    func test_fetchJetpackConnectionURL_correctly_returns_parsed_url() throws {
        // Given
        let siteURL = "http://test.com"
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/jetpack/v4/connection/url"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connection-url")

        // When
        let result: Result<URL, Error> = waitFor { promise in
            remote.fetchJetpackConnectionURL { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let url = try XCTUnwrap(result.get())
        let expectedURL = "https://jetpack.wordpress.com/jetpack.authorize/1/?response_type=code&client_id=2099457"
        assertEqual(url.absoluteString, expectedURL)
    }

    func test_fetchJetpackConnectionURL_properly_relays_errors() {
        // Given
        let siteURL = "http://test.com"
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/jetpack/v4/connection/url"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<URL, Error> = waitFor { promise in
            remote.fetchJetpackConnectionURL { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_fetchJetpackConnectionUser_correctly_returns_parsed_url() throws {
        // Given
        let siteURL = "http://test.com"
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/jetpack/v4/connection/data"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "jetpack-connected-user")

        // When
        let result: Result<JetpackUser, Error> = waitFor { promise in
            remote.fetchJetpackConnectionUser { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let user = try XCTUnwrap(result.get())
        XCTAssertTrue(user.isConnected)
        XCTAssertNotNil(user.wpcomUser)
    }

    func test_fetchJetpackConnectionUser_properly_relays_errors() {
        // Given
        let siteURL = "http://test.com"
        let remote = JetpackConnectionRemote(siteURL: siteURL, network: network)
        let urlSuffix = "/jetpack/v4/connection/data"
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: urlSuffix, error: error)

        // When
        let result: Result<JetpackUser, Error> = waitFor { promise in
            remote.fetchJetpackConnectionUser { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }
}
