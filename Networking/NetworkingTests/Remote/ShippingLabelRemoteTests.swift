import XCTest
import TestKit
@testable import Networking

/// ShippingLabelRemote Unit Tests
///
final class ShippingLabelRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    private let network = MockupNetwork()

    /// Dummy Site ID
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_printShippingLabel_returns_ShippingLabelPrintData() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/print", filename: "shipping-label-print")

        // When
        let printData: ShippingLabelPrintData = try waitFor { promise in
            remote.printShippingLabel(siteID: self.sampleSiteID, shippingLabelID: 123, paperSize: "label") { result in
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
}
