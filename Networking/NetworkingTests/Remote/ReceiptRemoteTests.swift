import XCTest

@testable import Networking

final class ReceiptRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_retrieveReceipt_when_there_is_data_envelope_then_returns_parsed_data() throws {
        // Given
        let remote = ReceiptRemote(network: network)

        // When
        network.simulateResponse(requestUrlSuffix: "orders/123/receipt",
                                 filename: "receipt")
        let result = waitFor { promise in
            remote.retrieveReceipt(siteID: 123, orderID: 123) { result in
                promise(result)
            }
        }
        let receipt = try XCTUnwrap(result.get())

        // Then
        assertEqual("https://mywootestingstore.com/wc/file/transient/7e811be40195b17f82604592ed26b694868807", receipt.receiptURL)
        assertEqual("2024-01-27", receipt.expirationDate)
    }

    func test_retrieveReceipt_when_there_is_no_data_envelope_then_returns_parsed_data() throws {
        // Given
        let remote = ReceiptRemote(network: network)

        // When
        network.simulateResponse(requestUrlSuffix: "orders/123/receipt",
                                 filename: "receipt-without-data-envelope")
        let result = waitFor { promise in
            remote.retrieveReceipt(siteID: 123, orderID: 123) { result in
                promise(result)
            }
        }
        let receipt = try XCTUnwrap(result.get())

        // Then
        assertEqual("https://mywootestingstore.com/wc/file/transient/7e811be40195b17f82604592ed26b694868807", receipt.receiptURL)
        assertEqual("2024-01-27", receipt.expirationDate)
    }

    func test_retrieveReceipt_when_invoked_then_includes_force_new_parameter_as_true_by_default() throws {
        // Given
        let remote = ReceiptRemote(network: network)

        // When
        remote.retrieveReceipt { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["force_new"] as? String)
        assertEqual("true", received)
    }

    func test_retrieveReceipt_when_force_new_set_to_false_then_includes_force_new_parameter_as_false() throws {
        // Given
        let remote = ReceiptRemote(network: network)

        // When
        remote.retrieveReceipt(forceRegenerate: false) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["force_new"] as? String)
        assertEqual("false", received)
    }
}
