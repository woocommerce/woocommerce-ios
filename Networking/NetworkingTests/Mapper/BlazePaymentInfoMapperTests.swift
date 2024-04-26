import XCTest
@testable import Networking

final class BlazePaymentInfoMapperTests: XCTestCase {

    /// Verifies that the payment info is parsed.
    ///
    func test_BlazePaymentInfoMapper_parses_all_contents_in_response() throws {
        // When
        let info = try XCTUnwrap(mapLoadBlazePaymentInfoResponse())

        // Then
        let paymentMethods = info.paymentMethods
        XCTAssertEqual(paymentMethods.count, 1)
        let method = try XCTUnwrap(paymentMethods.first)
        XCTAssertEqual(method.id, "payment-method-id")
        XCTAssertEqual(method.type, .creditCard)
        XCTAssertEqual(method.name, "Visa **** 4689")
        XCTAssertEqual(method.info.lastDigits, "4689")
        XCTAssertEqual(method.info.expiring.year, 2025)
        XCTAssertEqual(method.info.expiring.month, 2)
        XCTAssertEqual(method.info.nickname, "")
        XCTAssertEqual(method.info.cardholderName, "John Doe")
    }

}

private extension BlazePaymentInfoMapperTests {
    /// Returns the BlazePaymentInfo output from `blaze-payment-info.json`
    ///
    func mapLoadBlazePaymentInfoResponse() throws -> BlazePaymentInfo? {
        guard let response = Loader.contentsOf("blaze-payment-info") else {
            return nil
        }
        return try BlazePaymentInfoMapper().map(response: response)
    }
}
