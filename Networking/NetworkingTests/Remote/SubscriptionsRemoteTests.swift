import XCTest
@testable import Networking

final class SubscriptionsRemoteTests: XCTestCase {

    /// Mock Network Wrapper
    ///
    private let network = MockNetwork()

    /// Sample Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Sample Order ID
    ///
    private let sampleOrderID: Int64 = 12345

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load Subscriptions tests

    /// Verifies that loadSubscriptions properly parses the `subscription-list` sample response.
    ///
    func test_loadSubscriptions_returns_parsed_subscriptions() throws {
        // Given
        let remote = SubscriptionsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "subscriptions", filename: "subscription-list")

        // When
        let result = waitFor { promise in
            remote.loadSubscriptions(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let subscriptions = try XCTUnwrap(result.get())
        XCTAssertEqual(subscriptions.count, 2)
    }
    /// Verifies that loadSubscriptions properly relays Networking Layer errors.
    ///
    func test_loadSubscriptions_properly_relays_networking_errors() throws {
        // Given
        let remote = SubscriptionsRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "subscriptions", error: error)

        // When
        let result = waitFor { promise in
            remote.loadSubscriptions(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 403))
    }

}
