import XCTest
@testable import Networking

/// Unit Tests for `ShippingLabelCreationEligibilityMapper`
///
class ShippingLabelCreationEligibilityMapperTests: XCTestCase {
    /// Sample Site ID
    private let sampleSiteID: Int64 = 123456

    /// Sample Order ID
    private let sampleOrderID: Int64 = 123

    func test_shipping_label_creation_eligibility_success_is_properly_parsed() throws {
        // Given
        let response = try XCTUnwrap(mapEligibilityResponse(from: "shipping-label-eligibility-success"))

        // Then
        XCTAssertEqual(response.isEligible, true)
        XCTAssertEqual(response.reason, nil)
    }

    func test_shipping_label_creation_eligibility_failure_is_properly_parsed() throws {
        // Given
        let response = try XCTUnwrap(mapEligibilityResponse(from: "shipping-label-eligibility-failure"))

        // Then
        XCTAssertEqual(response.isEligible, false)
        XCTAssertEqual(response.reason, "no_selected_payment_method_and_user_cannot_manage_payment_methods")
    }
}

/// Private Helpers
///
private extension ShippingLabelCreationEligibilityMapperTests {

    /// Returns the `ShippingLabelCreationEligibilityMapper` output upon receiving `filename` (Data Encoded)
    ///
    func mapEligibilityResponse(from filename: String) -> ShippingLabelCreationEligibilityResponse? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ShippingLabelCreationEligibilityMapper().map(response: response)
    }
}
