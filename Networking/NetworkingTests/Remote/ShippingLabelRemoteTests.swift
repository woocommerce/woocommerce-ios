import XCTest
import TestKit
@testable import Networking

/// ShippingLabelRemote Unit Tests
///
final class ShippingLabelRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    private let network = MockNetwork()

    /// Dummy Site ID
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_loadShippingLabels_returns_shipping_labels_and_settings() throws {
        // Given
        let orderID: Int64 = 630
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)", filename: "order-shipping-labels")

        // When
        let result = try waitFor { promise in
            remote.loadShippingLabels(siteID: self.sampleSiteID, orderID: orderID) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.settings, .init(siteID: sampleSiteID, orderID: orderID, paperSize: .label))
        XCTAssertEqual(response.shippingLabels.count, 2)
    }

    func test_printShippingLabel_returns_ShippingLabelPrintData() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/print", filename: "shipping-label-print")

        // When
        let printData: ShippingLabelPrintData = try waitFor { promise in
            remote.printShippingLabel(siteID: self.sampleSiteID, shippingLabelID: 123, paperSize: .label) { result in
                guard let printData = try? result.get() else {
                    XCTFail("Error printing shipping label: \(String(describing: result.failure))")
                    return
                }
                promise(printData)
            }
        }

        // Then
        XCTAssertEqual(printData.mimeType, "application/pdf")
        XCTAssertFalse(printData.base64Content.isEmpty)
    }

    func test_refundShippingLabel_returns_refund_on_success() throws {
        // Given
        let orderID = Int64(279)
        let shippingLabelID = Int64(134)
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)/\(shippingLabelID)/refund", filename: "shipping-label-refund-success")

        // When
        let result: Result<ShippingLabelRefund, Error> = try waitFor { promise in
            remote.refundShippingLabel(siteID: self.sampleSiteID,
                                       orderID: orderID,
                                       shippingLabelID: shippingLabelID) { result in
                promise(result)
            }
        }

        // Then
        let refund = try XCTUnwrap(result.get())
        XCTAssertEqual(refund, .init(dateRequested: Date(timeIntervalSince1970: 1607331363.627), status: .pending))
    }

    func test_refundShippingLabel_returns_error_on_failure() throws {
        // Given
        let orderID = Int64(279)
        let shippingLabelID = Int64(134)
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)/\(shippingLabelID)/refund", filename: "shipping-label-refund-error")

        // When
        let result: Result<ShippingLabelRefund, Error> = try waitFor { promise in
            remote.refundShippingLabel(siteID: self.sampleSiteID,
                                       orderID: orderID,
                                       shippingLabelID: shippingLabelID) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = DotcomError
            .unknown(code: "wcc_server_error_response",
                     message: "Error: The WooCommerce Shipping & Tax server returned: Bad Request Unable to request refund. " +
                        "The parcel has been shipped. ( 400 )")
        XCTAssertEqual(result.failure as? DotcomError, expectedError)
    }
}
