import XCTest

@testable import Networking

final class ReceiptRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    private let sampleSiteID: Int64 = 12345

    private let sampleOrderID: Int64 = 6789

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_retrieveReceipt_when_there_is_data_envelope_then_returns_parsed_data() throws {
        // Given
        let remote = ReceiptRemote(network: network)
        let endpoint = "orders/\(sampleOrderID)/receipt"
        let filename = "receipt"

        // When
        network.simulateResponse(requestUrlSuffix: endpoint, filename: filename)

        let result = waitFor { promise in
            remote.retrieveReceipt(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
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
        let endpoint = "orders/\(sampleOrderID)/receipt"
        let filename = "receipt-without-data-envelope"

        // When
        network.simulateResponse(requestUrlSuffix: endpoint, filename: filename)

        let result = waitFor { promise in
            remote.retrieveReceipt(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
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
        remote.retrieveReceipt(siteID: sampleSiteID, orderID: sampleOrderID) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["force_new"] as? String)
        assertEqual("true", received)
    }

    func test_retrieveReceipt_when_force_new_set_to_false_then_includes_force_new_parameter_as_false() throws {
        // Given
        let remote = ReceiptRemote(network: network)
        let forceRegenerate = false

        // When
        remote.retrieveReceipt(siteID: sampleSiteID, orderID: sampleOrderID, forceRegenerate: forceRegenerate) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["force_new"] as? String)
        assertEqual("false", received)
    }

    func test_retrieveReceipt_when_expiration_date_is_unset_then_sends_expiration_days_parameter_as_default_2_days() throws {
        // Given
        let remote = ReceiptRemote(network: network)

        // When
        remote.retrieveReceipt(siteID: sampleSiteID, orderID: sampleOrderID) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["expiration_days"] as? String)
        assertEqual("2", received)
    }

    func test_retrieveReceipt_when_expiration_date_is_set_then_sends_expiration_days_parameter_as_default_days_passed_in() throws {
        // Given
        let remote = ReceiptRemote(network: network)
        let expirationDays = 365

        // When
        remote.retrieveReceipt(siteID: sampleSiteID, orderID: sampleOrderID, expirationDays: expirationDays) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["expiration_days"] as? String)
        assertEqual("365", received)
    }
}
