import XCTest
@testable import Networking
@testable import NetworkingCore

final class RefundsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    private let sampleOrderID: Int64 = 5678

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    /// Verifies that `createRefund` attaches caller-supplied custom headers (POS staff attribution) to the request.
    ///
    func test_createRefund_attaches_custom_headers_to_request() throws {
        // Given
        let remote = RefundsRemote(network: network)
        let refund = Refund.fake()
        let headers = ["X-WC-POS-Request": "1", "X-WC-POS-Staff-Id": "7", "X-WC-POS-Initiator-Id": "9"]

        // When
        remote.createRefund(for: sampleSiteID, by: sampleOrderID, refund: refund, customHeaders: headers) { _, _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        XCTAssertEqual(request.customHeaders, headers)
    }

    /// Verifies that `createRefund` sends no custom headers when none are supplied.
    ///
    func test_createRefund_without_custom_headers_sends_none() throws {
        // Given
        let remote = RefundsRemote(network: network)
        let refund = Refund.fake()

        // When
        remote.createRefund(for: sampleSiteID, by: sampleOrderID, refund: refund) { _, _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        XCTAssertTrue(request.customHeaders.isEmpty)
    }
}
