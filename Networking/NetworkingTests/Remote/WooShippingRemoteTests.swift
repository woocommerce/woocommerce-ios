import XCTest
import TestKit
@testable import Networking

/// WooShippingTests Unit Tests
///
final class WooShippingRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    private let network = MockNetwork()

    /// Dummy Site ID
    private let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    private let sampleOrderID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_createPackage_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "wooshipping-create-package-success")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: ShippingLabelCustomPackage.fake(),
                                 predefinedOption: ShippingLabelPredefinedOption.fake()) { result in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertTrue(successResponse)
    }

    func test_createPackage_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "wooshipping-create-package-error")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: ShippingLabelCustomPackage.fake(),
                                 predefinedOption: ShippingLabelPredefinedOption.fake()) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = DotcomError
            .unknown(code: "duplicate_custom_package_names_of_existing_packages",
                     message: "At least one of the new custom packages has the same name as existing packages.")
        XCTAssertEqual(result.failure as? DotcomError, expectedError)
    }

    func test_createPackage_returns_missingPackage_error_with_no_packages() throws {
        // Given
        let remote = WooShippingRemote(network: network)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: nil,
                                 predefinedOption: nil) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = WooShippingRemote.ShippingError.missingPackage
        XCTAssertEqual(result.failure as? WooShippingRemote.ShippingError, expectedError)
    }
}
