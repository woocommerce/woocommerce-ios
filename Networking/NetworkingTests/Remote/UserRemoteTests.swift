import XCTest
@testable import Networking


/// UserRemote Unit Tests
///
final class UserRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    func test_loadUserInfo_correctly_returns_parsed_user() throws {
        // Given
        let remote = UserRemote(network: network)
        let siteID: Int64 = 1234
        let urlSuffix = "sites/\(siteID)/users/me"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "user-complete")

        // When
        let result: Result<User, Error> = waitFor { promise in
            remote.loadUserInfo(for: siteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let user = try XCTUnwrap(result.get())
        XCTAssertEqual(user.siteID, siteID)
    }

    func test_loadUserInfo_properly_relays_errors() {
        // Given
        let remote = UserRemote(network: network)
        let siteID: Int64 = 1234

        // When
        let result: Result<User, Error> = waitFor { promise in
            remote.loadUserInfo(for: siteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
